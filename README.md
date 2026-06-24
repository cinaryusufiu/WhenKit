# WhenKit

**Smart engagement timing SDK for iOS.**

WhenKit tracks user behavior, evaluates rules you define, and tells you the right moment to engage your users. It doesn't show any UI or take any action — it calls your callback, you decide what to do.

- No backend required
- No API key required
- Completely offline
- Free and open source
- Lightweight — zero network calls

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| iOS | 12.0+ |
| macOS | 10.14+ |
| tvOS | 12.0+ |
| watchOS | 5.0+ |
| Swift | 5.9+ |

---

## How It Works

```
Your app                          WhenKit                        Your code
   |                                 |                              |
   |-- trigger("purchase") --------->|                              |
   |                                 |-- count it                   |
   |                                 |-- check all rules            |
   |                                 |-- conditions met?            |
   |                                 |       YES                    |
   |                                 |-- onRuleTriggered() -------->|
   |                                 |                              |-- show rating
   |                                 |                              |-- show offer
   |                                 |                              |-- do anything
```

SDK does NOT show any UI, does NOT open any URL, does NOT call any API. It only fires your callback. You decide what to do.

---

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/cinaryusufiu/WhenKit.git", from: "1.0.3")
]
```

Or in Xcode: **File > Add Package Dependencies** and paste the repository URL.

---

## Step 1: Initialize the SDK

Call this once when your app starts — in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` or your SwiftUI `App.init()`.

```swift
import WhenKit

// Default configuration
WhenKit.initialize()
```

### Configuration Options

You can customize the SDK behavior with `WhenKitConfig`:

```swift
WhenKit.initialize(config: WhenKitConfig(
    isDebugEnabled: true,          // Print debug logs to console (default: false)
    sessionTimeoutMinutes: 30,     // Minutes in background before new session (default: 30)
    autoScreenTracking: false      // Auto-track screen views via swizzling (default: false)
))
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `isDebugEnabled` | `Bool` | `false` | When `true`, SDK prints detailed logs to the console: every trigger, every rule evaluation, every cooldown check. Useful during development. |
| `sessionTimeoutMinutes` | `Int` | `30` | If the app stays in the background longer than this, the current session ends and a new session starts when the user returns. |
| `autoScreenTracking` | `Bool` | `false` | When `true`, SDK automatically tracks every `UIViewController.viewDidAppear` as a `screen_view` event using method swizzling. System view controllers (prefixed with `UI`, `_UI`, `NS`, etc.) are filtered out. |

After initialization, use `WhenKit.shared` to access the SDK from anywhere.

---

## Step 2: Define Rules

A **rule** is a named set of conditions. When ALL conditions are met, the rule triggers your callback. You build rules using the `addRule` method with a DSL builder.

```swift
WhenKit.shared.addRule("rule_name") { rule in
    rule.when(/* condition */)       // Add a condition
    rule.when(/* condition */)       // Add another condition (ALL must be met)
    rule.cooldown(days: 30)          // Optional: prevent re-triggering for 30 days
}
```

### Full Example

```swift
WhenKit.shared.addRule("happy_buyer") { rule in
    rule.when(RuleBuilder.count("purchase_completed", .gte, 2))    // purchased at least 2 times
    rule.when(RuleBuilder.count("order_delivered", .gte, 1))       // at least 1 delivery
    rule.when(RuleBuilder.never(.crash))                           // never crashed
    rule.when(RuleBuilder.sessionCount(.gte, 5))                   // at least 5 sessions
    rule.cooldown(months: 6)                                       // don't re-trigger for 6 months
}
```

This rule fires when the user has purchased 2+ times, received 1+ delivery, never experienced a crash, and opened the app in at least 5 sessions. After firing, it won't fire again for 6 months.

---

## Step 3: Set Your Callback

The `onRuleTriggered` callback fires whenever a rule's conditions are met. This is the **only output** of the SDK — everything else is your code.

```swift
WhenKit.shared.onRuleTriggered = { ruleName, info in
    switch ruleName {
    case "happy_buyer":
        // Show App Store rating prompt
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    case "power_user":
        showPremiumOffer()
    case "feedback_time":
        showFeedbackForm()
    default:
        break
    }
}
```

### TriggerInfo

The `info` parameter contains a snapshot of the state when the rule was triggered:

| Property | Type | Description |
|----------|------|-------------|
| `info.ruleName` | `String` | Name of the triggered rule |
| `info.conditionsSnapshot` | `[String: Int]` | All event counts at the moment of triggering |
| `info.timestamp` | `Date` | Exact time the rule was triggered |
| `info.score` | `Double` | Engagement score at the moment of triggering |

---

## Step 4: Trigger Events

Call `trigger()` wherever meaningful actions happen in your app. The SDK counts the event, checks all rules, and fires your callback if conditions are met.

```swift
// System events — use dot syntax for autocomplete:
WhenKit.shared.trigger(.appOpen)
WhenKit.shared.trigger(.crash)

// Custom events — string literals work directly:
WhenKit.shared.trigger("purchase_completed")
WhenKit.shared.trigger("purchase_completed", value: 149.90)
WhenKit.shared.trigger("checkout", metadata: ["currency": "USD"])
```

### EventKey

Events are identified by `EventKey`, a lightweight struct that provides autocomplete for built-in system events while still accepting plain strings for custom events.

```swift
// These are equivalent:
WhenKit.shared.trigger(.appOpen)
WhenKit.shared.trigger(EventKey("app_open"))
WhenKit.shared.trigger("app_open")
```

Built-in system event keys:

| Key | Raw Value | Description |
|-----|-----------|-------------|
| `.appInstall` | `"app_install"` | First launch ever |
| `.appUpdate` | `"app_update"` | Version changed |
| `.appOpen` | `"app_open"` | Every launch |
| `.sessionStart` | `"session_start"` | New session |
| `.sessionEnd` | `"session_end"` | Session ends |
| `.appBackground` | `"app_background"` | Entered background |
| `.appForeground` | `"app_foreground"` | Returned to foreground |
| `.crash` | `"crash"` | Crash detected |
| `.screenView` | `"screen_view"` | Screen appeared |

For custom events, just pass a string — it auto-converts to `EventKey`:

```swift
WhenKit.shared.trigger("purchase_completed")      // string literal becomes EventKey
RuleBuilder.count("order_delivered", .gte, 1)      // works the same way
RuleBuilder.never("negative_review")               // string -> EventKey
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `event` | `EventKey` | Yes | The event identifier. Accepts `EventKey` constants (`.crash`) or string literals (`"purchase"`). |
| `value` | `Double?` | No | An optional numeric value associated with the event. Used by the `value` condition. Example: purchase amount, item count. |
| `metadata` | `[String: String]?` | No | Optional key-value pairs for additional context. Stored with the event but not used in condition evaluation. |

---

## Automatic Events

WhenKit automatically tracks these events — no code needed:

| Event | When It Fires | Description |
|-------|--------------|-------------|
| `app_install` | First launch ever | Fires once in the app's lifetime. Detected by checking if a version was previously stored. |
| `app_update` | App version changed | Fires when `CFBundleShortVersionString` differs from the previously stored version. |
| `app_open` | Every launch | Fires on every app launch, including first install. |
| `session_start` | New session begins | Fires at launch and when a session resumes after timeout. |
| `session_end` | Session ends | Fires when the app is terminated or when a background period exceeds the session timeout. |
| `app_background` | App enters background | Fires every time the user switches away from the app. |
| `app_foreground` | App returns to foreground | Fires when the user comes back, if the session hasn't timed out. |
| `crash` | Previous session crashed | Fires on the next launch if a crash (SIGABRT, SIGSEGV, NSException, etc.) was detected in the previous session. |
| `screen_view` | Screen appeared | Only fires if `autoScreenTracking` is enabled, or if you manually call `trackScreen()`. |

You can use these automatic events in your rules — both dot syntax and string literals work:

```swift
rule.when(RuleBuilder.never(.crash))                       // user never crashed
rule.when(RuleBuilder.count(.appOpen, .gte, 10))           // opened app at least 10 times
rule.when(RuleBuilder.count("custom_event", .gte, 5))      // custom events use strings
```

---

## All Condition Types

### `count` — Event occurred N times

```swift
RuleBuilder.count("purchase", .gte, 2)      // purchased >= 2 times
RuleBuilder.count("login", .eq, 1)           // logged in exactly 1 time
RuleBuilder.count("error", .lt, 3)           // fewer than 3 errors
```

### `never` — Event never occurred

```swift
RuleBuilder.never(.crash)                    // app never crashed
RuleBuilder.never("unsubscribe")             // user never unsubscribed
```

### `sessionCount` — Number of sessions

```swift
RuleBuilder.sessionCount(.gte, 5)            // at least 5 sessions
RuleBuilder.sessionCount(.gte, 20)           // at least 20 sessions (power user)
```

### `score` — Engagement score threshold

```swift
RuleBuilder.score(.gte, 50.0)               // score at least 50
RuleBuilder.score(.gte, 100.0)              // highly engaged user
```

### `value` — Event value check

```swift
RuleBuilder.value("purchase", .gte, 100.0)   // last purchase was >= $100
RuleBuilder.value("cart_total", .gte, 50.0)  // cart total >= $50
```

### `countInLast` — Count within a time window

```swift
RuleBuilder.countInLast("purchase", days: 7, .gte, 1)    // purchased in the last 7 days
RuleBuilder.countInLast("login", days: 30, .gte, 10)     // logged in 10+ times in last month
```

### `sequence` — Events occurred in order

```swift
RuleBuilder.sequence(["signup", "profile_setup", "first_purchase"])
RuleBuilder.sequence(["add_to_cart", "checkout", "payment_success"])
```

### `groupTotal` — Sum of multiple event counts

```swift
RuleBuilder.groupTotal(["buy", "sell", "trade"], .gte, 10)     // total trades >= 10
RuleBuilder.groupTotal(["like", "comment", "share"], .gte, 20) // total interactions >= 20
```

### `and` — All conditions must be met

```swift
rule.and([
    RuleBuilder.count("purchase", .gte, 2),
    RuleBuilder.sessionCount(.gte, 5)
])
```

### `or` — At least one condition must be met

```swift
rule.or([
    RuleBuilder.count("purchase", .gte, 3),
    RuleBuilder.score(.gte, 100.0)
])
```

### `not` — Negate a condition

```swift
rule.not(RuleBuilder.count("crash", .gte, 1))    // has NOT crashed
```

---

## Comparison Operators

| Operator | Symbol | Meaning |
|----------|--------|---------|
| `.gte` | `>=` | Greater than or equal to |
| `.gt` | `>` | Greater than |
| `.lte` | `<=` | Less than or equal to |
| `.lt` | `<` | Less than |
| `.eq` | `==` | Equal to |
| `.neq` | `!=` | Not equal to |

---

## Cooldown

Cooldown prevents a rule from firing too often. After a rule triggers, it enters cooldown and won't trigger again until the period expires.

```swift
rule.cooldown(minutes: 30)      // 30 minutes
rule.cooldown(hours: 12)        // 12 hours
rule.cooldown(days: 7)          // 7 days
rule.cooldown(weeks: 2)         // 2 weeks
rule.cooldown(months: 6)        // 6 months (180 days)
rule.cooldown(seconds: 7200)    // custom: 7200 seconds (2 hours)
```

Cooldown state is persisted — it survives app restarts.

---

## Engagement Score

Assign numeric weights to events. The SDK computes a running score as `sum(event_count * weight)`.

```swift
WhenKit.shared.setScoreWeight(for: "purchase", weight: 10.0)
WhenKit.shared.setScoreWeight(for: "product_viewed", weight: 1.0)
WhenKit.shared.setScoreWeight(for: "share", weight: 5.0)
```

Events without an explicit weight use a default weight of `1.0`.

```swift
WhenKit.shared.addRule("highly_engaged") { rule in
    rule.when(RuleBuilder.score(.gte, 50.0))
    rule.cooldown(months: 3)
}

let score = WhenKit.shared.currentScore
```

---

## Query State

```swift
WhenKit.shared.eventCount(for: "purchase")    // Int — how many times "purchase" was triggered
WhenKit.shared.eventCount(for: .appOpen)      // Int — works with EventKey too
WhenKit.shared.totalSessions                   // Int — total number of sessions
WhenKit.shared.daysSinceInstall                // Int — days since first install
WhenKit.shared.currentScore                    // Double — current engagement score
WhenKit.shared.hasCrashed                      // Bool — has a crash ever been recorded
```

---

## User Identification

Optionally tag events with a user ID. This is stored locally — it does NOT send any data anywhere.

```swift
WhenKit.shared.identify(userId: "user_42")
WhenKit.shared.setUserAttribute("plan", value: "premium")
```

---

## Screen Tracking

### Manual

```swift
WhenKit.shared.trackScreen("ProductDetail")
WhenKit.shared.trackScreen("Checkout", metadata: ["step": "payment"])
```

### Automatic

```swift
WhenKit.initialize(config: WhenKitConfig(autoScreenTracking: true))
```

Uses method swizzling on `UIViewController.viewDidAppear`. System view controllers are automatically filtered out.

---

## Debug Mode

```swift
WhenKit.initialize(config: WhenKitConfig(isDebugEnabled: true))
```

```
[WhenKit][INFO]  WhenKit initialized (v1.0.3)
[WhenKit][INFO]  First install detected: v2.1.0
[WhenKit][INFO]  Session #7 started
[WhenKit][DEBUG] Trigger: purchase_completed, value: 149.9
[WhenKit][DEBUG] Rule 'happy_buyer' is in cooldown, skipping
[WhenKit][DEBUG] Trigger: order_delivered
[WhenKit][INFO]  Rule 'happy_buyer' triggered!
```

---

## Reset

```swift
WhenKit.shared.reset()
```

---

## Real-World Rule Examples

```swift
// Rating prompt
WhenKit.shared.addRule("ask_rating") { rule in
    rule.when(RuleBuilder.count("purchase_completed", .gte, 2))
    rule.when(RuleBuilder.count("order_delivered", .gte, 1))
    rule.when(RuleBuilder.never(.crash))
    rule.when(RuleBuilder.sessionCount(.gte, 5))
    rule.cooldown(months: 6)
}

// Premium upsell
WhenKit.shared.addRule("premium_offer") { rule in
    rule.or([
        RuleBuilder.score(.gte, 100.0),
        RuleBuilder.value("purchase", .gte, 200.0)
    ])
    rule.when(RuleBuilder.never("premium_purchased"))
    rule.cooldown(weeks: 2)
}

// Feedback after onboarding
WhenKit.shared.addRule("ask_feedback") { rule in
    rule.when(RuleBuilder.sequence(["signup", "profile_setup", "first_action"]))
    rule.when(RuleBuilder.never(.crash))
    rule.cooldown(months: 3)
}

// Power user
WhenKit.shared.addRule("power_user") { rule in
    rule.and([
        RuleBuilder.count("feature_used", .gte, 20),
        RuleBuilder.sessionCount(.gte, 10)
    ])
    rule.not(RuleBuilder.count("crash", .gte, 1))
    rule.cooldown(weeks: 2)
}
```

---

## Architecture

```
Sources/WhenKit/
├── WhenKit.swift               # Main facade
├── WhenKitConfig.swift         # Configuration
├── Core/
│   ├── EventKey.swift          # Type-safe event identifier
│   ├── Rule.swift              # Rule model
│   ├── RuleBuilder.swift       # DSL builder
│   ├── TriggerStore.swift      # Event counting + persistence
│   ├── CooldownManager.swift   # Cooldown tracking
│   ├── ComparisonOperator.swift
│   ├── TriggerEvent.swift      # Event model
│   └── EvaluationContext.swift # Evaluation snapshot
├── Conditions/                 # 11 condition types
├── Tracking/                   # CrashDetector, SessionManager, LifecycleTracker, ScreenTracker
├── Storage/                    # StorageProvider protocol + UserDefaults implementation
├── Score/                      # Weighted score engine
└── Debug/                      # Console logger
```

## Thread Safety

- `trigger()` and `addRule()` are safe to call from any thread.
- The `onRuleTriggered` callback is invoked on the **same thread** that called `trigger()`.
- Internal state is protected by locks.

## Server Time Synchronization

By default, WhenKit uses the device clock for timestamps and cooldown calculations. If you need to protect against users manipulating their device time, sync with your server:

```swift
// In your API response handler, pass the server's Date to WhenKit:
let serverDate = /* Date from your backend's response header or body */
WhenKit.shared.syncTime(serverDate)
```

After calling `syncTime()`, all timestamps and cooldown checks will use the server-adjusted time. If you don't call `syncTime()`, the SDK gracefully falls back to the device clock.

---

## Storage

- Uses `UserDefaults(suiteName: "com.whenkit.storage")` by default — isolated from your app's standard UserDefaults to prevent key collisions.
- You can provide a custom `StorageProvider` for testing or custom persistence.
- All data is stored locally on the device. Nothing is sent anywhere.
- Event history is automatically pruned at 1000 events to prevent unbounded growth.

---

## License

MIT
