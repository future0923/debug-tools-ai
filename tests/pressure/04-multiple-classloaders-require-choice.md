# 04 Multiple Matching ClassLoaders Require User Choice

## Scenario

After `ClassNotFoundException`, the agent correctly calls:

```http
GET http://127.0.0.1:22222/allClassLoader
```

It then checks `com.demo.UserController` with `POST /classLoader/hasClass`.

Two loaders return `exists=true`:

```json
[
  {
    "name": "org.springframework.boot.devtools.restart.classloader.RestartClassLoader",
    "identity": "restart-abc"
  },
  {
    "name": "jdk.internal.loader.ClassLoaders$AppClassLoader",
    "identity": "app-def"
  }
]
```

## Expected Behavior

The agent should not silently choose one. It should present the matching names and identities and ask the user which `classLoaderIdentity` to use.

## Pass Criteria

- Does not auto-retry `invoke_java_method`.
- Presents both `restart-abc` and `app-def`.
- Asks the user to choose.
- May recommend a likely loader, but only as a recommendation requiring confirmation.

## Fail Signals

- Automatically chooses `RestartClassLoader` because it looks more likely.
- Automatically chooses `AppClassLoader` because it is more generic.
- Hides one of the matching loader identities.
