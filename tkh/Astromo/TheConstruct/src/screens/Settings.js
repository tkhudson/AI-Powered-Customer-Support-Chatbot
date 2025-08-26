import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  Picker,
  TextInput,
  Button,
  StyleSheet,
  ScrollView,
} from "react-native";
import * as SecureStore from "expo-secure-store";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Platform } from "react-native";

// Sample AI providers (expandable)
const providers = ["OpenAI", "Claude", "Grok"];

const Settings = ({ navigation }) => {
  const [selectedProvider, setSelectedProvider] = useState(providers[0]);
  const [apiKey, setApiKey] = useState("");

  // Platform-aware storage wrappers
  const isWeb = Platform.OS === "web";

  const getItem = async (key) => {
    try {
      if (isWeb) {
        return await AsyncStorage.getItem(key);
      } else {
        return await SecureStore.getItemAsync(key);
      }
    } catch (error) {
      console.error(`Error getting ${key}:`, error);
      return null;
    }
  };

  const setItem = async (key, value) => {
    try {
      if (isWeb) {
        await AsyncStorage.setItem(key, value);
      } else {
        await SecureStore.setItemAsync(key, value);
      }
    } catch (error) {
      console.error(`Error setting ${key}:`, error);
      throw error; // Propagate to caller for handling
    }
  };

  useEffect(() => {
    const loadSettings = async () => {
      try {
        const storedProvider = await getItem("aiProvider");
        const storedKey = await getItem("aiApiKey");
        if (storedProvider) setSelectedProvider(storedProvider);
        if (storedKey) setApiKey(storedKey);
      } catch (error) {
        alert("Failed to load settings: " + error.message);
      }
    };
    loadSettings();
  }, []);

  const handleSave = async () => {
    try {
      await setItem("aiProvider", selectedProvider);
      await setItem("aiApiKey", apiKey);
      alert("Settings saved successfully!");
      navigation.navigate("MainMenu");
    } catch (error) {
      alert(
        "Failed to save settings: " + error.message + ". Please try again.",
      );
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Settings</Text>

      <Text style={styles.label}>AI Provider:</Text>
      <Picker
        selectedValue={selectedProvider}
        onValueChange={(itemValue) => setSelectedProvider(itemValue)}
        style={styles.picker}
      >
        {providers.map((provider) => (
          <Picker.Item key={provider} label={provider} value={provider} />
        ))}
      </Picker>

      <Text style={styles.label}>API Key:</Text>
      <TextInput
        style={styles.textInput}
        secureTextEntry
        onChangeText={(text) => setApiKey(text)}
        value={apiKey}
        placeholder="Enter your API key..."
      />

      <Text style={styles.warning}>
        Note: API calls may incur costs from your chosen provider. Keys are
        stored securely on your device. We do not access or share them. Usage is
        logged for transparency.
      </Text>
      {Platform.OS === "web" && (
        <Text style={styles.warning}>
          Warning: On web, storage is not fully secure (uses localStorage). For
          better security, use the native app.
        </Text>
      )}

      <Button title="Save Settings" onPress={handleSave} />
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
  warning: {
    fontSize: 14,
    color: "red",
    marginBottom: 20,
    textAlign: "center",
  },
});

export default Settings;
