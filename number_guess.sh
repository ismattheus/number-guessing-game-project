#!/bin/bash

# Connection to the require database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Program for he 'Number Guessing Game'

echo -e "\n~~~~~~~ NUMBER GUESSING GAME ~~~~~~"

MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  echo -e "\nSelect an option:"
  echo -e "\n1. Guess the number\n2. Leaderboard\n3. Exit\n"
  read MAIN_MENU_SELECTION

  case $MAIN_MENU_SELECTION in
    1) GUESS_NUMBER ;;
    2) LEADERBOARD ;;
    3) EXIT ;;
    *) MAIN_MENU ;;
  esac
}

GUESS_NUMBER() {
  # generate random number between 1 and 1000
  SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

  # ask for username until is valid
  while true
  do
    echo -e "\nEnter your username:"
    read USERNAME

    #not empty
    if [[ -z $USERNAME ]]
    then
      echo -e "\nUsername cannot be empty. Try again please."
      continue
    fi

    # username with no spaces or special characters less than 22 character (- _ ! . allowed)
    if [[ ! $USERNAME =~ ^[A-Za-z0-9_.-]{1,22}$ ]]
    then
      echo -e "\nUse only letters, numbers, _ . - (max 22 chars, no spaces). Try again please."
      continue
    fi

    break
  done

  # check username existance in DB
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")

  if [[ -z $USER_ID ]]
  then
    USER_ID_INSERT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME');")
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")
    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
  else
    # get games played by returning user
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_id=$USER_ID;")

    # get best game for returning user
    BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE user_id=$USER_ID;")

    echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi

  # GUESSING SECTION

  echo -e "\nGuess the secret number between 1 and 1000:"

  GUESSES=0

  while true
  do

    read GUESS

    # check if the input is an integer
    if [[ ! $GUESS =~ ^[0-9]+$ ]]
    then
      echo -e "\nThat is not an integer, guess again:"
      continue
    fi

    GUESSES=$(( GUESSES + 1 ))

    # compare
    if (( GUESS < SECRET_NUMBER ))
    then
      echo -e "\nIt's higher than that, guess again:"
    elif (( GUESS > SECRET_NUMBER ))
    then
      echo -e "\nIt's lower than that, guess again:"
    else
      echo -e "\nYou guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!\n"
      break
    fi
  done

  # save game records
  ACTUAL_GAMES_PLAYED=$(( GAMES_PLAYED + 1 ))
  GAMES_INSERT=$($PSQL "INSERT INTO games(user_id, game_number, random_number, guess) VALUES($USER_ID, $ACTUAL_GAMES_PLAYED, $SECRET_NUMBER, $GUESSES);")

  # update games_played and best_game on users table
  USERS_UPDATE=$($PSQL "UPDATE users
        SET games_played = $ACTUAL_GAMES_PLAYED,
            best_game = CASE
                          WHEN best_game IS NULL OR $GUESSES < best_game THEN $GUESSES
                          ELSE best_game
                        END
        WHERE user_id = $USER_ID;")
  
  MAIN_MENU
}

LEADERBOARD() {
  TOP=$($PSQL "SELECT u.username, g.guess, g.random_number
               FROM games g
               JOIN users u USING(user_id)
               ORDER BY g.guess ASC
               LIMIT 10;")

  echo -e "\n----------------- LEADERBOARD -----------------\n"
  printf "%-4s %-15s %-10s %-15s\n" "" "USER" "GUESSES" "RANDOM NUMBER"

  POS=1
  echo "$TOP" | while IFS="|" read USERNAME GUESSES RANDOM_NUMBER
  do
    [[ -z $USERNAME ]] && continue
    printf "%-4s %-15s %-10s %-15s\n" "$POS" "$USERNAME" "$GUESSES" "$RANDOM_NUMBER"
    POS=$((POS + 1))
  done

  MAIN_MENU
}

EXIT() {
  echo -e "\nThank you for playing the game!\n"
}

# executes the main menu
MAIN_MENU
