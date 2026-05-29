# PocketWise App Blueprint

## Overview

PocketWise is a Flutter application designed for personal finance management. It allows users to track their income and expenses, view transaction history, analyze spending statistics, and manage their settings. The application is built with a focus on a clean, modern user interface and a simple, intuitive user experience.

## Features

*   **Dashboard:** Provides a summary of the user's financial status, including current balance, recent transactions, and a spending overview.
*   **Transaction History:** A comprehensive list of all transactions, with options to search and filter by type (income, expenses, bills).
*   **Add Transaction:** A form to add new income or expense transactions, with options to select a category, set a date, and add notes.
*   **Statistics:** Visual representations of spending habits, including expenses by category and weekly spending trends.
*   **Settings:** Options to configure the application, such as setting reminders, managing privacy and data, and viewing application information.

## Refactoring: Directory Structure

### Plan

1.  Create a new directory `lib/screens` to house all the UI screen files.
2.  Move the following files from `lib/` to `lib/screens/`:
    *   `dashboard_screen.dart`
    *   `transaction_history.dart`
    *   `add_transaction.dart`
    *   `statistics_screen.dart`
    *   `settings_screen.dart`
3.  Update the import statements in `lib/main.dart` to reflect the new file locations.

### Execution

The refactoring has been completed as planned. All screen files are now located in the `lib/screens` directory, and the `lib/main.dart` file has been updated with the correct import paths. This new structure improves the organization of the project and makes it easier to navigate and maintain.
