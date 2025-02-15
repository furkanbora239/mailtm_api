### This package is a wrapper for the mail.tm api.

Since the dart package recommended on the web site is not suitable for my conditions, I wrote my own.

I strongly recommend that you read the mail.tm api terms and conditions before using this package. 
mail.tm api is for personal use only. reselling is prohibited by the api terms.

At the moment it only supports two main features, because I didn't need the rest of the features

1- Mail creation
2- Check inbox
3- Quota control

## Features

For now, I have only written as much as I need, but in order not to be incomplete, I will support other features provided by the API, such as delete, update.

## Usage

```dart
const mail = TempMail.createMail();
```

You can check the `/example` folder for longer examples. 

## Additional information

The package may have some shortcomings or bugs, so please contact me via github if you have any problems or suggestions.
