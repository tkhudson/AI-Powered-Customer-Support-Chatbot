import React from 'react';
import { View, Text, Button, StyleSheet } from 'react-native';

const MainMenu = ({ navigation }) => {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>The Construct</Text>
      <Button
        title="New Game"
        onPress={() => navigation.navigate('NewGame')} // Placeholder navigation
      />
      <Button
        title="Continue Session"
        onPress={() => navigation.navigate('ContinueSession')} // Placeholder
      />
      <Button
        title="Settings"
        onPress={() => navigation.navigate('Settings')} // Placeholder
      />
      <Button
        title="Exit"
        onPress={() => { /* Handle exit or something */ }}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    marginBottom: 40,
  },
});

export default MainMenu;
