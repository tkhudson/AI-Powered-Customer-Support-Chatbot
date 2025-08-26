import React, { useState } from "react";
import {
  View,
  Text,
  Picker,
  TextInput,
  Button,
  StyleSheet,
  ScrollView,
} from "react-native";

// Sample data based on D&D 5e (can be expanded or loaded from data files)
const races = ["Human", "Elf", "Dwarf", "Halfling", "Tiefling", "Dragonborn"];
const classes = ["Fighter", "Wizard", "Rogue", "Cleric", "Paladin", "Warlock"];
const backgrounds = [
  "Acolyte",
  "Criminal",
  "Folk Hero",
  "Noble",
  "Sage",
  "Soldier",
];

const CharacterCreation = ({ navigation, route }) => {
  const [selectedRace, setSelectedRace] = useState(races[0]);
  const [selectedClass, setSelectedClass] = useState(classes[0]);
  const [selectedBackground, setSelectedBackground] = useState(backgrounds[0]);
  const [backstory, setBackstory] = useState("");

  const config = route.params?.config || {};

  const handleSubmit = () => {
    const character = {
      race: selectedRace,
      class: selectedClass,
      background: selectedBackground,
      backstory,
    };
    // TODO: Integrate with AI for suggestions/validation, save character, navigate to next screen
    console.log("Character created:", character);
    navigation.navigate("GameSession", { config, character });
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Character Creation</Text>

      <Text style={styles.label}>Race:</Text>
      <Picker
        selectedValue={selectedRace}
        onValueChange={(itemValue) => setSelectedRace(itemValue)}
        style={styles.picker}
      >
        {races.map((race) => (
          <Picker.Item key={race} label={race} value={race} />
        ))}
      </Picker>

      <Text style={styles.label}>Class:</Text>
      <Picker
        selectedValue={selectedClass}
        onValueChange={(itemValue) => setSelectedClass(itemValue)}
        style={styles.picker}
      >
        {classes.map((cls) => (
          <Picker.Item key={cls} label={cls} value={cls} />
        ))}
      </Picker>

      <Text style={styles.label}>Background:</Text>
      <Picker
        selectedValue={selectedBackground}
        onValueChange={(itemValue) => setSelectedBackground(itemValue)}
        style={styles.picker}
      >
        {backgrounds.map((bg) => (
          <Picker.Item key={bg} label={bg} value={bg} />
        ))}
      </Picker>

      <Text style={styles.label}>Backstory:</Text>
      <TextInput
        style={styles.textInput}
        multiline
        numberOfLines={4}
        onChangeText={(text) => setBackstory(text)}
        value={backstory}
        placeholder="Enter your character's backstory..."
      />

      <Button title="Submit Character" onPress={handleSubmit} />
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
    minHeight: 100,
  },
});

export default CharacterCreation;
