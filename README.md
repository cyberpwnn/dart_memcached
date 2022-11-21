Simple in-memory key to object cache with expiry

## Features

Dynamic values mean there's no type checking or serialization. This means you can store anything you want in the cache.

## Usage

```dart
double someValue = getCachedSync(
    id: "some.key", 
    getter: () => 1.5, 
    duration: Duration(minutes: 5));

getCached(
    id: "some.async", 
    getter: () async => 1.5, 
    duration: Duration(minutes: 5))
.then((value) => print(value));
```