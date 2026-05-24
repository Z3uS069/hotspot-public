# Hotspot Web - Flutter to React Migration Guide

## Quick Start

```bash
cd hotspot-web
npm install
npm run dev
```

The app will open at `http://localhost:3000`

---

## Project Structure

```
hotspot-web/
├── src/
│   ├── App.tsx                 # Main app component (replaces MyApp + AppShell)
│   ├── App.css                 # Global app styles
│   ├── main.tsx               # React entry point
│   ├── index.css              # Global CSS
│   │
│   ├── types/
│   │   └── app.ts             # TypeScript type definitions
│   │
│   ├── models/
│   │   └── index.ts           # Data models (matches Flutter models)
│   │
│   ├── store/
│   │   └── index.ts           # Zustand store (replaces Provider)
│   │
│   ├── hooks/
│   │   └── index.ts           # Custom React hooks
│   │
│   ├── utils/
│   │   └── theme.ts           # Theme utilities
│   │
│   ├── pages/                 # Page components (one per Flutter page)
│   │   ├── RoleSelectionPage.tsx
│   │   ├── LoginPage.tsx
│   │   ├── SignupPage.tsx
│   │   ├── SpaceSetupPage.tsx
│   │   ├── UserAppShell.tsx
│   │   └── AdminDashboardPage.tsx
│   │
│   └── components/            # Reusable UI components
│       └── index.ts           # Component stubs (replace Flutter widgets)
```

---

## Flutter ↔ React Mapping

### 1. State Management

**Flutter:**
```dart
class AppProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  void toggleTheme() { ... }
}

// In widget:
Consumer<AppProvider>(
  builder: (context, appProvider, child) { ... }
)
```

**React:**
```typescript
// Store (Zustand):
export const useAppStore = create<AppState>((set) => ({
  isDarkMode: true,
  toggleTheme: () => set((state) => ({ isDarkMode: !state.isDarkMode })),
}));

// In component:
const { isDarkMode, toggleTheme } = useAppStore();
// or
const isDarkMode = useAppStore((state) => state.isDarkMode);
```

**File Reference:**
- Flutter: `lib/providers/app_provider.dart`
- React: `src/store/index.ts`

---

### 2. Main App Entry

**Flutter:**
```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildAppTheme(isDarkMode),
      home: const AppShell(),
    );
  }
}
```

**React:**
```typescript
// src/main.tsx
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)

// src/App.tsx
function App() {
  return (
    <div className="app">
      <BackgroundBlobs ... />
      <ScreenRouter />
    </div>
  );
}
```

**File References:**
- Flutter: `lib/main.dart`
- React: `src/main.tsx` + `src/App.tsx`

---

### 3. Navigation & Screen Routing

**Flutter:**
```dart
// AppShell handles screen switching via AppProvider.screen
switch (app.screen) {
  case AppScreen.roleSelect:
    return const RoleSelectionPage();
  case AppScreen.signup:
    return SignupPage(role: app.role!);
  // ... etc
}

// Navigate:
context.read<AppProvider>().setScreen(AppScreen.UserApp);
```

**React:**
```typescript
// src/App.tsx handles screen routing
function ScreenRouter() {
  const screen = useAppStore((state) => state.screen);
  const role = useAppStore((state) => state.role);

  switch (screen) {
    case AppScreen.RoleSelect:
      return <RoleSelectionPage />;
    case AppScreen.Signup:
      return <SignupPage role={role || AppRole.User} />;
    // ... etc
  }
}

// Navigate:
const { setScreen } = useNavigation();
setScreen(AppScreen.UserApp);
```

**File References:**
- Flutter: `lib/app_shell.dart` + `lib/providers/app_provider.dart`
- React: `src/App.tsx` + `src/store/index.ts` + `src/hooks/index.ts`

---

### 4. Theme & Colors

**Flutter:**
```dart
class AppColors {
  static const Color appBgDark = Color(0xFF0B1426);
  static const Color appAccent = Color(0xFF00C9A7);
  // ...
}

class AppTheme {
  static Color bg(BuildContext context) =>
      isDark(context) ? AppColors.appBgDark : AppColors.appBgLight;
  
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? Colors.white : AppColors.lightTextPrimary;
}

// In widget:
Container(
  color: AppTheme.bg(context),
  child: Text(
    'Hello',
    style: TextStyle(color: AppTheme.textPrimary(context)),
  ),
)
```

**React:**
```typescript
// src/utils/theme.ts
export const AppColors = {
  appBgDark: '#0B1426',
  appAccent: '#00C9A7',
  // ...
};

export const getThemeColors = (isDarkMode: boolean) => ({
  bg: isDarkMode ? AppColors.appBgDark : AppColors.appBgLight,
  textPrimary: isDarkMode ? 'white' : AppColors.lightTextPrimary,
});

// In component:
function MyComponent() {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);
  
  return (
    <div style={{ backgroundColor: colors.bg, color: colors.textPrimary }}>
      Hello
    </div>
  );
}
```

**File References:**
- Flutter: `lib/theme.dart`
- React: `src/utils/theme.ts`

---

### 5. Page Examples

#### Role Selection Page

**Flutter:**
```dart
class RoleSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text('Choose your role'),
            ElevatedButton(
              onPressed: () {
                context.read<AppProvider>().setRole(AppRole.user);
                context.read<AppProvider>().setScreen(AppScreen.signup);
              },
              child: Text('I\'m a User'),
            ),
            // ...
          ],
        ),
      ),
    );
  }
}
```

**React:**
```typescript
// src/pages/RoleSelectionPage.tsx
function RoleSelectionPage() {
  const { setScreen, setRole } = useNavigation();
  const colors = getThemeColors(isDarkMode);

  const handleSelectRole = (role: AppRole) => {
    setRole(role);
    setScreen(AppScreen.Signup);
  };

  return (
    <div style={{ padding: '2rem' }}>
      <h1>Choose your role</h1>
      <button onClick={() => handleSelectRole(AppRole.User)}>
        I'm a User
      </button>
      {/* ... */}
    </div>
  );
}
```

**File References:**
- Flutter: `lib/pages/role_selection_page.dart`
- React: `src/pages/RoleSelectionPage.tsx`

---

### 6. Widgets/Components

**Flutter Widget Example:**
```dart
// lib/widgets/space_card.dart
class SpaceCard extends StatelessWidget {
  final SpaceModel space;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          children: [
            Image.network(space.imageUrl),
            Text(space.name),
            Text('\$${space.price}'),
          ],
        ),
      ),
    );
  }
}
```

**React Component Example:**
```typescript
// src/components/SpaceCard.tsx
interface SpaceCardProps {
  space: SpaceModel;
  onTap: () => void;
}

function SpaceCard({ space, onTap }: SpaceCardProps) {
  const colors = getThemeColors(isDarkMode);

  return (
    <div
      onClick={onTap}
      style={{
        backgroundColor: colors.cardBg,
        borderRadius: '0.5rem',
        cursor: 'pointer',
      }}
    >
      <img src={space.imageUrl} alt={space.name} />
      <h3>{space.name}</h3>
      <p>${space.price}</p>
    </div>
  );
}
```

**File References:**
- Flutter widgets: `lib/widgets/`
- React components: `src/components/`

---

## Type System Mapping

### Flutter → React TypeScript

| Flutter | React TypeScript |
|---------|-----------------|
| `enum AppScreen { roleSelect, signup, ... }` | `enum AppScreen { RoleSelect = 'roleSelect', ... }` |
| `class SpaceModel { ... }` | `interface SpaceModel { ... }` |
| `@override` | N/A (handled automatically) |
| `late` variables | Optional properties `?` |
| `const` constructor | Immutable interfaces |
| `BuildContext` | React hooks (`useAppStore`, `useDarkMode`) |
| `ChangeNotifier` | Zustand store |
| `Consumer<T>` | Hook pattern with selectors |

---

## Hooks Reference

### 1. useDarkMode()

**Replaces:**
- `context.watch<AppProvider>().isDarkMode`
- `AppTheme.isDark(context)`

```typescript
const { isDarkMode, toggleTheme, setDarkMode } = useDarkMode();
```

### 2. useNavigation()

**Replaces:**
- `context.read<AppProvider>().screen`
- `context.read<AppProvider>().setScreen(...)`

```typescript
const { screen, setScreen, role, setRole, activeTab, setActiveTab } = useNavigation();
```

### 3. useOverlays()

**Replaces:**
- Accessing overlay state from AppProvider

```typescript
const {
  selectedSpaceId,
  selectSpace,
  isBookingFormOpen,
  setIsBookingFormOpen,
  // ...
} = useOverlays();
```

---

## Key Differences

### Styling

**Flutter:**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [...],
  ),
  child: Text('Button'),
)
```

**React:**
```typescript
<div style={{
  backgroundColor: 'blue',
  borderRadius: '0.5rem',
  boxShadow: '...',
}}>
  Button
</div>
```

### Event Handling

**Flutter:**
```dart
GestureDetector(
  onTap: () { ... },
  onLongPress: () { ... },
)
```

**React:**
```typescript
<div
  onClick={() => { ... }}
  onContextMenu={() => { ... }}
/>
```

### Lists

**Flutter:**
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

**React:**
```typescript
{items.map((item, index) => (
  <ItemComponent key={index} item={item} />
))}
```

---

## Next Steps

### 1. Implement Core Pages (Priority)
- [ ] HomePage (Map view)
- [ ] SpacesPage (List view)
- [ ] SpaceDetailsPage (Detail view)
- [ ] BookingFormPage (Booking flow)

### 2. Implement Widgets/Components
- [ ] SpaceCard
- [ ] BottomNav
- [ ] GlassInput
- [ ] GradientButton
- [ ] NotificationPanel

### 3. Backend Integration
- [ ] Setup API client
- [ ] Implement authentication
- [ ] Add data fetching hooks
- [ ] Add error handling

### 4. Features
- [ ] Map integration (Google Maps or Mapbox)
- [ ] QR code scanning (use qrcode.react for generation)
- [ ] Image upload/cropping
- [ ] Location services

### 5. Polish
- [ ] Add animations (Framer Motion or React Spring)
- [ ] Add error boundaries
- [ ] Add loading states
- [ ] Add form validation

---

## Useful Commands

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm build

# Preview production build
npm run preview

# Lint (when configured)
npm run lint
```

---

## Resources

- **React Docs:** https://react.dev
- **TypeScript Docs:** https://www.typescriptlang.org/docs/
- **Zustand Docs:** https://github.com/pmndrs/zustand
- **Vite Docs:** https://vitejs.dev

---

## Flutter ↔ React Conversion Cheat Sheet

| Task | Flutter | React |
|------|---------|-------|
| Get state | `context.watch(Provider)` | `useAppStore()` |
| Update state | `context.read(Provider).setValue()` | State setter from hook |
| Dark mode | `AppTheme.isDark(context)` | `useDarkMode().isDarkMode` |
| Theme colors | `AppTheme.bg(context)` | `getThemeColors(isDarkMode).bg` |
| Navigation | `context.read(AppProvider).setScreen()` | `useNavigation().setScreen()` |
| Conditional render | `if (condition) widget else other` | `condition ? <Widget/> : <Other/>` |
| Lists | `ListView.builder()` | `array.map()` |
| Input handling | `TextEditingController` | `useState()` |
| Lifecycle | `initState()` | `useEffect()` |
| Styling | `style: TextStyle(...)` | `style={{...}}` |

---

Good luck with the migration! 🚀
