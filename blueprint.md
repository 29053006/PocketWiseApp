# PocketWise App Blueprint

## Overview

PocketWise is a Flutter application designed for personal finance management. It allows users to track their income and expenses, view transaction history, analyze spending statistics, and manage their settings. The application is built with a focus on a clean, modern user interface and a simple, intuitive user experience.

## Features

*   **Dashboard:** Provides a summary of the user's financial status, including current balance, recent transactions, and a spending overview.
*   **Transaction History:** A comprehensive list of all transactions, with options to search and filter by type (income, expenses, bills).
*   **Add Transaction:** A form to add new income or expense transactions, with options to select a category, set a date, and add notes.
*   **Statistics:** Visual representations of spending habits, including expenses by category and weekly spending trends.
*   **Settings:** Options to configure the application, such as setting reminders, managing privacy and data, and viewing application information.
*   **Currency Conversion:** Allows users to switch the display currency between USD and COP.

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

## SQLite Integration

### Plan

1.  **Add Dependencies:** Add `sqflite` and `path_provider` to `pubspec.yaml`.
2.  **Create Data Model:** Create a `Transaction` model in `lib/models/transaction_model.dart`.
3.  **Create Database Helper:** Create a `DatabaseHelper` class in `lib/data/database_helper.dart` to handle all database operations.
4.  **Integrate with UI:** Update the UI screens (`add_transaction.dart`, `dashboard_screen.dart`, `transaction_history.dart`, `statistics_screen.dart`) to use the `DatabaseHelper` to manage transactions.

### Execution

The SQLite integration has been completed as planned. The application now uses a local SQLite database to persist transaction data. All UI screens have been updated to interact with the database, providing a fully functional and persistent user experience.

## Currency Conversion

### Plan

1.  **Create CurrencyProvider:** Create a `CurrencyProvider` to manage the selected currency (USD or COP) and persist the user's choice using `shared_preferences`.
2.  **Integrate Provider:** Integrate the `CurrencyProvider` into the app's widget tree in `lib/main.dart`.
3.  **Modify Settings Screen:** Add a UI control (e.g., a dropdown) to `lib/screens/settings_screen.dart` to allow users to change the currency.
4.  **Apply Currency Formatting:** Update all screens that display monetary values to respect the selected currency, apply the correct conversion rate, and show the appropriate currency symbol.
5.  **Create Utility Function:** Create a `currency_util.dart` file with a `formatCurrency` function.

### Execution

The currency conversion feature has been successfully implemented. A `CurrencyProvider` was created to manage the state, and `shared_preferences` was used for persistence. The settings screen now includes a dropdown for currency selection. All relevant screens (`Dashboard`, `Transaction History`, `Statistics`) were updated to use the `formatCurrency` utility and listen for currency changes, ensuring the UI updates automatically.

## Bug Fix: Lifecycle Management

### Issue 1: `Looking up a deactivated widget's ancestor is unsafe`

A `FlutterError` was occurring due to accessing `Provider.of(context)` within the `dispose()` method. At that point in the widget lifecycle, the context is no longer valid for this operation.

### Plan 1

1.  Cache the `CurrencyProvider` instance in a state variable within `didChangeDependencies()`.
2.  Use the cached instance in `dispose()` to safely remove the listener.

### Execution 1

The fix was applied to `DashboardScreen`, `TransactionHistoryScreen`, and `StatisticsScreen`, resolving the initial lifecycle error.

### Issue 2: `setState() called after dispose()`

A subsequent `FlutterError` occurred because `setState()` was being called from the `CurrencyProvider`'s listener even after the widget had been disposed, creating a race condition.

### Plan 2

In the `_refresh...()` methods of each affected screen, wrap the `setState()` call in a conditional check for `if (mounted)`.

### Execution 2

This final fix has been applied. By checking `if (mounted)`, we ensure that `setState()` is only called when the widget is still part of the widget tree, fully resolving the lifecycle issues and stabilizing the application.

## Bug Fix: Calculation Logic

### Issue

An error in the calculation logic was causing incorrect financial summaries. The core problem was that currency conversion was mixed with formatting, and the order of operations was not explicit. The app performed calculations on raw USD values and then converted the final sum, which, while sometimes mathematically sound, is a poor design practice that can lead to subtle bugs.

### Plan

1.  **Refactor `currency_util.dart`:** Separate the conversion logic from the formatting logic. Create a new `convertCurrency` function to handle the mathematical conversion and modify the existing `formatCurrency` function to only handle string formatting.
2.  **Update UI Screens:** In `DashboardScreen`, `TransactionHistoryScreen`, and `StatisticsScreen`, modify the logic to first convert all transaction amounts from USD to the selected currency using `convertCurrency`.
3.  **Perform Calculations:** Perform all calculations (balance, sums by category, etc.) on these newly converted values.
4.  **Format for Display:** Use the `formatCurrency` function only to format the final, calculated values for display in the UI.

### Execution

The calculation logic has been successfully refactored across all relevant screens. By ensuring that currency conversion happens before any calculation, the logic is now explicit, correct, and easier to maintain. This resolves the calculation errors and improves the overall robustness of the application.
