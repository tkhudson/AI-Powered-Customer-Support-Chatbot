import * as SecureStore from "expo-secure-store";
import axios from "axios";

import fiveEData from "../data/5eData.json";

// Basic stub response function (fallback if no API key or error)
function generateStubResponse(playerAction, config, character, history) {
  // Simple logic similar to previous stub
  if (
    playerAction.toLowerCase().includes("roll") ||
    playerAction.toLowerCase().includes("check")
  ) {
    const roll = Math.floor(Math.random() * 20) + 1; // Simplified d20 roll
    return `You attempt the action in the ${config.theme || "fantasy"} world... Roll result: ${roll}. ${roll >= 10 ? "Success!" : "Failure!"}`;
  }
  return `The DM narrates: As a ${character.race || "brave"} ${character.class || "adventurer"}, you ${playerAction}. Suddenly, a shadowy figure appears! What next?`;
}

// Function to retrieve stored AI settings
async function getAISettings() {
  try {
    const provider = (await SecureStore.getItemAsync("aiProvider")) || "OpenAI";
    const apiKey = await SecureStore.getItemAsync("aiApiKey");
    return { provider, apiKey };
  } catch (error) {
    console.error("Error retrieving AI settings:", error);
    return { provider: "OpenAI", apiKey: null };
  }
}

// Function to build a prompt with context
function buildPrompt(playerAction, config, character, history) {
  // Extract relevant 5e data
  const raceInfo = fiveEData.races.find((r) => r.name === character.race) || {
    traits: [],
  };
  const classInfo = fiveEData.classes.find(
    (c) => c.name === character.class,
  ) || { features: [] };

  // Simple keyword extraction for skills/spells in action (expand as needed)
  const mentionedSkills = fiveEData.skills.filter((s) =>
    playerAction.toLowerCase().includes(s.name.toLowerCase()),
  );
  const mentionedSpells = fiveEData.spells.filter((s) =>
    playerAction.toLowerCase().includes(s.name.toLowerCase()),
  );

  const raceDetails = raceInfo.traits.join(", ");
  const classDetails = classInfo.features.join(", ");
  const skillDetails = mentionedSkills
    .map((s) => `${s.name} (${s.ability}): ${s.description}`)
    .join("; ");
  const spellDetails = mentionedSpells
    .map((s) => `${s.name} (Level ${s.level}, ${s.school}): ${s.description}`)
    .join("; ");

  const systemMessage = `
You are an AI Dungeon Master for a D&D 5e game. Adhere to 5e rules: character stats (e.g., Strength, Dexterity), classes (${character.class || "Fighter"}), races (${character.race || "Human"}), skills, spells, combat (initiative, attack rolls, saving throws).
Session details: Theme - ${config.theme || "Classic Fantasy"}, Difficulty - ${config.difficulty || "Medium"}, Time - ${config.sessionTime || "1 hour"}, Mode - ${config.campaignMode || "One-shot"}.
Player character: Race - ${character.race || "Human"} (Traits: ${raceDetails}), Class - ${character.class || "Fighter"} (Features: ${classDetails}), Background - ${character.background || "Acolyte"}, Backstory - ${character.backstory || "A wandering hero"}.

Relevant skills: ${skillDetails || "None mentioned"}.
Relevant spells: ${spellDetails || "None mentioned"}.

Conversation history: ${history.map((msg) => `${msg.isDM ? "DM" : "Player"}: ${msg.text}`).join("\n")}.

Respond narratively, resolve actions (e.g., roll virtual dice if needed, describe outcomes based on 5e rules), keep it engaging and true to 5e.
Player's current action: ${playerAction}
`;

  return [
    { role: "system", content: systemMessage },
    { role: "user", content: playerAction },
  ];
}

// Main function to query AI or fallback to stub
async function queryAI(playerAction, config, character, history) {
  const { provider, apiKey } = await getAISettings();

  if (!apiKey) {
    console.log("No API key found, using stub response.");
    return generateStubResponse(playerAction, config, character, history);
  }

  try {
    let response;
    if (provider === "OpenAI") {
      response = await axios.post(
        "https://api.openai.com/v1/chat/completions",
        {
          model: "gpt-3.5-turbo",
          messages: buildPrompt(playerAction, config, character, history),
          max_tokens: 300, // Adjust as needed for cost/response length
          temperature: 0.7, // For creativity
        },
        {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
          },
        },
      );
      const aiText = response.data.choices[0].message.content.trim();
      console.log("API Usage:", response.data.usage); // Log for transparency/cost tracking
      return aiText;
    }
    // TODO: Add support for other providers like Claude (Anthropic) or Grok
    // Example for Claude: Use 'https://api.anthropic.com/v1/complete' with appropriate format
    else {
      throw new Error(`Unsupported provider: ${provider}`);
    }
  } catch (error) {
    console.error("AI API Error:", error);
    return generateStubResponse(playerAction, config, character, history); // Fallback
  }
}

export { queryAI };
