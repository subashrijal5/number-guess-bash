#!/bin/bash

# Set the database connection variables
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Prompt the user for a username
echo -e "Enter your username:"
read USERNAME

# Check if the username exists in the database
USER_DATA=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username='$USERNAME'")

# If the username doesn't exist, insert a new user
if [[ -z $USER_DATA ]]; then
  INSERT_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  USER_DATA=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username='$USERNAME'")
  IFS='|' read -ra USER_FIELDS <<< "$USER_DATA"
  USERNAME=${USER_FIELDS[0]}
  GAMES_PLAYED=${USER_FIELDS[1]}
  BEST_GAME=${USER_FIELDS[2]}
else
  # Extract user data from the query result
  IFS='|' read -ra USER_FIELDS <<< "$USER_DATA"
  USERNAME=${USER_FIELDS[0]}
  GAMES_PLAYED=${USER_FIELDS[1]}
  BEST_GAME=${USER_FIELDS[2]}
  # Display the welcome message with user statistics
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses. "
fi

# Generate a random secret number between 1 and 1000
SECRET_NUMBER=$((1 + $RANDOM % 1000))
GUESSES=0

# Game loop
echo "Guess the secret number between 1 and 1000:"
while true; do
  read GUESS

  # Check if the input is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Update the number of guesses
  ((GUESSES++))

  # Check if the guess is correct
  if ((GUESS == SECRET_NUMBER)); then
    break
  elif ((GUESS < SECRET_NUMBER)); then
    echo "It's higher than that, guess again:"
  else
    echo "It's lower than that, guess again:"
  fi
done

# Update the user's game statistics
UPDATED_GAMES_PLAYED=$((GAMES_PLAYED + 1))
UPDATED_BEST_GAME=$(($BEST_GAME < $GUESSES ? $BEST_GAME : $GUESSES))
UPDATE_QUERY="UPDATE users SET games_played='$UPDATED_GAMES_PLAYED', best_game='$UPDATED_BEST_GAME' WHERE username='$USERNAME'"
UPDATE_RESULT=$($PSQL "$UPDATE_QUERY")
echo $UPDATE_RESULT


# Display the congratulatory message
echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
