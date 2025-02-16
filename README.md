### This package is a wrapper for the mail.tm API.

Since the Dart package recommended on the website is not suitable for my conditions, I wrote my own.

I strongly recommend that you read the mail.tm API terms and conditions before using this package. 
The mail.tm API is for personal use only. Reselling is prohibited by the API terms.

At the moment, it only supports three main features, because I didn't need the rest of the features:

1. Mail creation
2. Check inbox
3. Quota control

## Features

For now, I have only written as much as I need, but in order not to be incomplete, I will support other features provided by the API, such as delete and update.

## Usage

```dart
const mail = TempMail.createMail();
```

You can check the `/example` folder for longer examples. 

## Additional information

The package may have some shortcomings or bugs, so please contact me via GitHub if you have any problems or suggestions.
