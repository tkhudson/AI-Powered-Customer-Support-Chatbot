import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  Button,
  FlatList,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
} from "react-native";
import { rollD20 } from "../utils/diceRoller";
import { queryAI } from "../utils/aiService";

const GameSession = ({ navigation, route }) => {
  const config = route.params?.config || {};
  const character = route.params?.character || {};

  const initialMessage = `Welcome to your ${config.theme || "fantasy"} adventure! As a ${character.race || "brave"} ${character.class || "adventurer"}, you find yourself in a mysterious setting. What do you do?`;

  const [messages, setMessages] = useState([
    { id: "1", text: initialMessage, isDM: true },
  ]);
  const [inputText, setInputText] = useState("");

  const handleSubmit = async () => {
    if (!inputText.trim()) return;

    // Add player message
    const newMessages = [
      ...messages,
      { id: `${messages.length + 1}`, text: inputText, isDM: false },
    ];

    // Stubbed AI response
    const aiResponse = await queryAI(
      inputText,
      config,
      character,
      messages.slice(-5),
    );
    newMessages.push({
      id: `${newMessages.length + 1}`,
      text: aiResponse,
      isDM: true,
    });

    setMessages(newMessages);
    setInputText("");
  };

  const handleRollD20 = (modifier = 0) => {
    const roll = rollD20(modifier);
    const rollMessage = `Dice Roll (d20 + ${modifier}): ${roll}`;
    setMessages([
      ...messages,
      { id: `${messages.length + 1}`, text: rollMessage, isDM: false },
    ]);
  };

  const renderMessage = ({ item }) => (
    <View
      style={[
        styles.message,
        item.isDM ? styles.dmMessage : styles.playerMessage,
      ]}
    >
      <Text style={styles.messageText}>{item.text}</Text>
    </View>
  );

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      keyboardVerticalOffset={80}
    >
      <FlatList
        data={messages}
        renderItem={renderMessage}
        keyExtractor={(item) => item.id}
        style={styles.chatList}
      />
      <View style={styles.inputContainer}>
        <TextInput
          style={styles.textInput}
          value={inputText}
          onChangeText={setInputText}
          placeholder="Enter your action..."
          multiline
        />
        <Button title="Submit" onPress={handleSubmit} />
        <Button title="Roll d20" onPress={() => handleRollD20(0)} />
      </View>
      <Button
        title="End Session"
        onPress={() => navigation.navigate("MainMenu")}
        color="red"
      />
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#f5f5f5",
  },
  chatList: {
    flex: 1,
    padding: 10,
  },
  message: {
    padding: 10,
    borderRadius: 10,
    marginVertical: 5,
    maxWidth: "80%",
  },
  dmMessage: {
    alignSelf: "flex-start",
    backgroundColor: "#d1e7dd",
  },
  playerMessage: {
    alignSelf: "flex-end",
    backgroundColor: "#cfe2ff",
  },
  messageText: {
    fontSize: 16,
  },
  inputContainer: {
    flexDirection: "row",
    padding: 10,
    borderTopWidth: 1,
    borderColor: "#ccc",
    backgroundColor: "#fff",
  },
  textInput: {
    flex: 1,
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 5,
    padding: 10,
    marginRight: 10,
  },
});

export default GameSession;
