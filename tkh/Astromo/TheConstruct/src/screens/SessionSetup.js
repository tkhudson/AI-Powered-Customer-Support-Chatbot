import React, { useState } from "react";
import {
  View,
  Text,
  Picker,
  TextInput,
  Switch,
  Button,
  StyleSheet,
  ScrollView,
} from "react-native";

// Sample options based on game plan
const themes = [
  "Classic D&D",
  "Modern Zombies",
  "Star Wars",
  "Post-Apocalyptic Wasteland",
  "Custom",
];
const difficulties = ["Easy", "Medium", "Hard"];
const sessionTimes = ["10 minutes", "30 minutes", "1 hour"];
const campaignModes = ["One-shot", "Ongoing"];

const SessionSetup = ({ navigation }) => {
  const [numPlayers, setNumPlayers] = useState(1);
  const [isAIDM, setIsAIDM] = useState(true); // Default to AI DM
  const [selectedTheme, setSelectedTheme] = useState(themes[0]);
  const [customTheme, setCustomTheme] = useState("");
  const [selectedDifficulty, setSelectedDifficulty] = useState(difficulties[1]);
  const [selectedSessionTime, setSelectedSessionTime] = useState(
    sessionTimes[1],
  );
  const [selectedCampaignMode, setSelectedCampaignMode] = useState(
    campaignModes[0],
  );

  const handleSubmit = () => {
    const config = {
      numPlayers,
      isAIDM,
      theme: selectedTheme === "Custom" ? customTheme : selectedTheme,
      difficulty: selectedDifficulty,
      sessionTime: selectedSessionTime,
      campaignMode: selectedCampaignMode,
    };
    // Navigate to CharacterCreation with config (can be used to customize session)
    navigation.navigate("CharacterCreation", { config });
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Session Setup</Text>

      <Text style={styles.label}>Number of Players (1-6):</Text>
      <Picker
        selectedValue={numPlayers}
        onValueChange={(itemValue) => setNumPlayers(itemValue)}
        style={styles.picker}
      >
        {[1, 2, 3, 4, 5, 6].map((num) => (
          <Picker.Item key={num} label={`${num}`} value={num} />
        ))}
      </Picker>

      <View style={styles.switchContainer}>
        <Text style={styles.label}>DM Mode: {isAIDM ? "AI" : "Player"}</Text>
        <Switch value={isAIDM} onValueChange={setIsAIDM} />
      </View>

      <Text style={styles.label}>Theme/Setting:</Text>
      <Picker
        selectedValue={selectedTheme}
        onValueChange={(itemValue) => setSelectedTheme(itemValue)}
        style={styles.picker}
      >
        {themes.map((theme) => (
          <Picker.Item key={theme} label={theme} value={theme} />
        ))}
      </Picker>
      {selectedTheme === "Custom" && (
        <TextInput
          style={styles.textInput}
          placeholder="Describe your custom theme..."
          value={customTheme}
          onChangeText={setCustomTheme}
        />
      )}

      <Text style={styles.label}>Difficulty:</Text>
      <Picker
        selectedValue={selectedDifficulty}
        onValueChange={(itemValue) => setSelectedDifficulty(itemValue)}
        style={styles.picker}
      >
        {difficulties.map((diff) => (
          <Picker.Item key={diff} label={diff} value={diff} />
        ))}
      </Picker>

      <Text style={styles.label}>Session Time:</Text>
      <Picker
        selectedValue={selectedSessionTime}
        onValueChange={(itemValue) => setSelectedSessionTime(itemValue)}
        style={styles.picker}
      >
        {sessionTimes.map((time) => (
          <Picker.Item key={time} label={time} value={time} />
        ))}
      </Picker>

      <Text style={styles.label}>Campaign Mode:</Text>
      <Picker
        selectedValue={selectedCampaignMode}
        onValueChange={(itemValue) => setSelectedCampaignMode(itemValue)}
        style={styles.picker}
      >
        {campaignModes.map((mode) => (
          <Picker.Item key={mode} label={mode} value={mode} />
        ))}
      </Picker>

      <Button title="Start Session" onPress={handleSubmit} />
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: "#fff",
  },
  title: {
    fontSize: 28,
    fontWeight: "bold",
    marginBottom: 20,
    textAlign: "center",
  },
  label: {
    fontSize: 18,
    marginTop: 10,
    marginBottom: 5,
  },
  picker: {
    height: 50,
    width: "100%",
    marginBottom: 15,
  },
  textInput: {
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 5,
    padding: 10,
    marginBottom: 20,
  },
  switchContainer: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 15,
  },
});

export default SessionSetup;
