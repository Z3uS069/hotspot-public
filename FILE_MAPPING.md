# Flutter → React File Mapping

## Complete File Reference Guide

This document provides a detailed mapping of every Flutter file to its React equivalent, with migration instructions.

---

## ENTRY POINTS

### lib/main.dart → src/main.tsx + src/App.tsx

**Flutter Code Structure:**
```dart
// lib/main.dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'Hotspot',
            theme: buildAppTheme(appProvider.isDarkMode),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
```

**React Equivalent:**

`src/main.tsx` - Entry point
```typescript
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
```

`src/App.tsx` - App component (replaces MyApp + AppShell)
```typescript
function App() {
  const { isDarkMode } = useDarkMode();
  return (
    <div className="app">
      <BackgroundBlobs isDarkMode={isDarkMode} isAdmin={isAdmin} />
      <ScreenRouter />
    </div>
  );
}
```

**Files Created:**
- ✅ `src/main.tsx`
- ✅ `src/App.tsx`
- ✅ `src/App.css`
- ✅ `src/index.css`

---

## THEME & STYLING

### lib/theme.dart → src/utils/theme.ts

**Flutter Structure:**
```dart
class AppColors {
  static const Color appBgDark = Color(0xFF0B1426);
  static const Color appCardDark = Color(0xFF152238);
  // ... 30+ color definitions
}

class AppTheme {
  static bool isDark(BuildContext context) => ...
  static Color bg(BuildContext context) => ...
  static Color textPrimary(BuildContext context) => ...
}
```

**React Equivalent:**
```typescript
export const AppColors = {
  appBgDark: '#0B1426',
  appCardDark: '#152238',
  // ... 30+ color definitions
};

export const getThemeColors = (isDarkMode: boolean) => ({
  bg: isDarkMode ? AppColors.appBgDark : AppColors.appBgLight,
  textPrimary: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
  // ...
});
```

**Migration Instructions:**
1. All color values are pre-mapped in `src/utils/theme.ts`
2. In components, use: `const colors = getThemeColors(isDarkMode);`
3. Apply colors via inline styles: `style={{ backgroundColor: colors.bg }}`

**Files Created:**
- ✅ `src/utils/theme.ts`

---

## STATE MANAGEMENT & PROVIDERS

### lib/providers/app_provider.dart → src/store/index.ts + src/hooks/index.ts

**Flutter Structure:**
```dart
enum AppScreen { roleSelect, signup, login, ... }
enum AppRole { user, admin }
enum AppTab { map, space, activity, saved }

class AppProvider extends ChangeNotifier {
  // Theme state
  bool _isDarkMode = true;
  void toggleTheme() { notifyListeners(); }
  
  // Navigation state
  AppScreen _screen = AppScreen.roleSelect;
  void setScreen(AppScreen screen) { notifyListeners(); }
  
  AppRole? _role;
  void setRole(AppRole role) { notifyListeners(); }
  
  // Overlay flags
  bool _isBookingFormOpen = false;
  void setIsBookingFormOpen(bool open) { notifyListeners(); }
  
  // ... more state
}
```

**React Equivalent:**

Zustand Store (`src/store/index.ts`):
```typescript
export const useAppStore = create<AppState>((set) => ({
  // Theme state
  isDarkMode: true,
  toggleTheme: () => set((state) => ({ isDarkMode: !state.isDarkMode })),
  
  // Navigation state
  screen: AppScreen.RoleSelect,
  setScreen: (screen: AppScreen) => set({ screen }),
  
  role: null,
  setRole: (role: AppRole) => set({ role }),
  
  // Overlay flags
  isBookingFormOpen: false,
  setIsBookingFormOpen: (open: boolean) => set({ isBookingFormOpen: open }),
  
  // ... more state
}));
```

Custom Hooks (`src/hooks/index.ts`):
```typescript
export const useDarkMode = () => {
  const isDarkMode = useAppStore((state) => state.isDarkMode);
  const toggleTheme = useAppStore((state) => state.toggleTheme);
  // ...
};

export const useNavigation = () => {
  const screen = useAppStore((state) => state.screen);
  const setScreen = useAppStore((state) => state.setScreen);
  // ...
};

export const useOverlays = () => { ... };
```

**Usage Comparison:**

Flutter:
```dart
// Reading state
final isDarkMode = context.watch<AppProvider>().isDarkMode;

// Updating state
context.read<AppProvider>().toggleTheme();
```

React:
```typescript
// Reading state
const { isDarkMode } = useDarkMode();
// or
const isDarkMode = useAppStore((state) => state.isDarkMode);

// Updating state
const { toggleTheme } = useDarkMode();
toggleTheme();
```

**Files Created:**
- ✅ `src/store/index.ts`
- ✅ `src/hooks/index.ts`
- ✅ `src/types/app.ts`

---

## MODELS & DATA STRUCTURES

### lib/models/ → src/models/index.ts

**Flutter Files:**
- `lib/models/space_model.dart`
- `lib/models/booking_model.dart`
- `lib/models/review_model.dart`

**React Equivalent (`src/models/index.ts`):**

All models converted to TypeScript interfaces:
```typescript
export interface SpaceModel {
  id: string;
  name: string;
  address: string;
  // ... all fields from Dart model
}

export interface BookingModel {
  id: string;
  spaceId: string;
  // ... all fields
}

export interface ReviewModel {
  id: string;
  spaceId: string;
  // ... all fields
}
```

**Migration Instructions:**
1. Models are already defined in `src/models/index.ts`
2. Match exact field names and types
3. Use for type-safe data handling

**Files Created:**
- ✅ `src/models/index.ts`

---

## PAGES (SCREENS)

### lib/pages/ → src/pages/

| Flutter File | React File | Status |
|---|---|---|
| `role_selection_page.dart` | `RoleSelectionPage.tsx` | ✅ Complete |
| `signup_page.dart` | `SignupPage.tsx` | ✅ Basic |
| `login_page.dart` | `LoginPage.tsx` | ✅ Basic |
| `space_setup_page.dart` | `SpaceSetupPage.tsx` | ⏳ Stub |
| `user_app_shell.dart` | `UserAppShell.tsx` | ✅ Shell |
| `admin_dashboard_page.dart` | `AdminDashboardPage.tsx` | ✅ Basic |
| `home_page.dart` | `HomePage.tsx` | ⏳ TODO |
| `spaces_page.dart` | `SpacesPage.tsx` | ⏳ TODO |
| `space_details_page.dart` | `SpaceDetailsPage.tsx` | ⏳ TODO |
| `booking_form_page.dart` | `BookingFormPage.tsx` | ⏳ TODO |
| `booking_requests_page.dart` | `BookingRequestsPage.tsx` | ⏳ TODO |
| `profile_page.dart` | `ProfilePage.tsx` | ⏳ TODO |
| `activity_page.dart` | `ActivityPage.tsx` | ⏳ TODO |
| `saved_page.dart` | `SavedPage.tsx` | ⏳ TODO |
| `my_qr_code_page.dart` | `MyQRCodePage.tsx` | ⏳ TODO |
| `scan_qr_code_page.dart` | `ScanQRCodePage.tsx` | ⏳ TODO |
| `directions_page.dart` | `DirectionsPage.tsx` | ⏳ TODO |

### Page Migration Template

**Flutter Pattern:**
```dart
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load initial data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: ListView(
        children: [
          // Content
        ],
      ),
    );
  }
}
```

**React Pattern:**
```typescript
interface HomePageProps {
  // Optional props
}

function HomePage(props: HomePageProps) {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);
  const { activeTab } = useNavigation();

  useEffect(() => {
    // Load initial data
  }, []);

  return (
    <div style={{ minHeight: '100vh' }}>
      <header>Home</header>
      {/* Content */}
    </div>
  );
}
```

**Implementation Checklist:**
- [ ] Define prop interface
- [ ] Import hooks (`useDarkMode`, `useNavigation`, etc.)
- [ ] Get theme colors: `const colors = getThemeColors(isDarkMode);`
- [ ] Use `useEffect()` instead of `initState()`
- [ ] Apply responsive styling
- [ ] Export as default

**Files Created:**
- ✅ `src/pages/RoleSelectionPage.tsx`
- ✅ `src/pages/LoginPage.tsx`
- ✅ `src/pages/SignupPage.tsx`
- ✅ `src/pages/SpaceSetupPage.tsx`
- ✅ `src/pages/UserAppShell.tsx`
- ✅ `src/pages/AdminDashboardPage.tsx`

---

## WIDGETS/COMPONENTS

### lib/widgets/ → src/components/

| Flutter File | React File | Status |
|---|---|---|
| `bottom_nav.dart` | `BottomNav.tsx` | ⏳ TODO |
| `space_card.dart` | `SpaceCard.tsx` | ⏳ TODO |
| `glass_input.dart` | `GlassInput.tsx` | ⏳ TODO |
| `gradient_button.dart` | `GradientButton.tsx` | ⏳ TODO |
| `header_widget.dart` | `HeaderWidget.tsx` | ⏳ TODO |
| `notification_panel.dart` | `NotificationPanel.tsx` | ⏳ TODO |
| `google_logo.dart` | `GoogleLogo.tsx` | ⏳ TODO |

### Component Migration Template

**Flutter Pattern:**
```dart
class SpaceCard extends StatelessWidget {
  final SpaceModel space;
  final VoidCallback onTap;
  
  const SpaceCard({
    required this.space,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          children: [
            Image.network(space.imageUrl),
            Text(space.name),
            Text('${space.price}/hr'),
          ],
        ),
      ),
    );
  }
}
```

**React Pattern:**
```typescript
interface SpaceCardProps {
  space: SpaceModel;
  onTap: () => void;
}

const SpaceCard: React.FC<SpaceCardProps> = ({ space, onTap }) => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);

  return (
    <div
      onClick={onTap}
      style={{
        backgroundColor: colors.cardBg,
        borderRadius: '0.75rem',
        border: `1px solid ${colors.borderColor}`,
        cursor: 'pointer',
        padding: '1rem',
        transition: 'all 0.3s ease',
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.transform = 'translateY(-4px)';
        e.currentTarget.style.boxShadow = '0 10px 20px rgba(0,0,0,0.1)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'translateY(0)';
        e.currentTarget.style.boxShadow = 'none';
      }}
    >
      <img src={space.imageUrl} alt={space.name} style={{ width: '100%', borderRadius: '0.5rem' }} />
      <h3 style={{ color: colors.textPrimary, marginTop: '0.75rem' }}>{space.name}</h3>
      <p style={{ color: colors.textSecondary }}>${space.price}/hr</p>
    </div>
  );
};
```

**Implementation Checklist:**
- [ ] Define props interface with `extends React.FC<Props>`
- [ ] Import theme utilities
- [ ] Apply colors via `getThemeColors()`
- [ ] Use inline `style` objects for styling
- [ ] Add event handlers (`onClick`, `onMouseEnter`, etc.)
- [ ] Add responsive breakpoints via media queries in CSS files
- [ ] Memoize with `React.memo()` if needed
- [ ] Export as default

**Files to Create:**
```
src/components/
├── BottomNav.tsx
├── SpaceCard.tsx
├── GlassInput.tsx
├── GradientButton.tsx
├── HeaderWidget.tsx
├── NotificationPanel.tsx
└── GoogleLogo.tsx
```

Template provided: ✅ `src/components/ExampleComponent.tsx`

---

## TYPE DEFINITIONS

### lib/ → src/types/

**Flutter Enums** → **TypeScript Enums:**
```dart
enum AppScreen { roleSelect, signup, login, ... }
```

```typescript
enum AppScreen {
  RoleSelect = 'roleSelect',
  Signup = 'signup',
  Login = 'login',
  // ...
}
```

**Flutter Classes** → **TypeScript Interfaces:**
```dart
class User {
  final String id;
  final String name;
  // ...
}
```

```typescript
interface User {
  id: string;
  name: string;
  // ...
}
```

**Files Created:**
- ✅ `src/types/app.ts`
- ✅ `src/models/index.ts`

---

## IMPLEMENTATION PRIORITY

### Phase 1: Core Structure ✅
- [x] Setup project structure
- [x] Create store/state management
- [x] Create theme system
- [x] Create base pages (auth screens)
- [x] Create routing logic

### Phase 2: Core Pages (2-3 hours)
- [ ] Implement `HomePage.tsx` (map + spaces list)
- [ ] Implement `SpacesPage.tsx` (full spaces list)
- [ ] Implement `SpaceDetailsPage.tsx` (details + reviews)
- [ ] Implement `BookingFormPage.tsx` (booking form)

### Phase 3: Widgets/Components (3-4 hours)
- [ ] `SpaceCard.tsx` - reusable card component
- [ ] `BottomNav.tsx` - tab navigation
- [ ] `GlassInput.tsx` - glassmorphism input
- [ ] `GradientButton.tsx` - styled button
- [ ] `HeaderWidget.tsx` - header with search

### Phase 4: User Features (3-4 hours)
- [ ] `ProfilePage.tsx` - user profile
- [ ] `ActivityPage.tsx` - booking history
- [ ] `SavedPage.tsx` - saved spaces
- [ ] `BookingRequestsPage.tsx` - booking management

### Phase 5: QR & Directions (2-3 hours)
- [ ] `MyQRCodePage.tsx` - QR code generation
- [ ] `ScanQRCodePage.tsx` - QR code scanning
- [ ] `DirectionsPage.tsx` - map directions

### Phase 6: Admin Features (2-3 hours)
- [ ] Complete `AdminDashboardPage.tsx`
- [ ] Complete `SpaceSetupPage.tsx`
- [ ] Admin booking management

### Phase 7: Polish & Integration (2-3 hours)
- [ ] Backend API integration
- [ ] Error handling
- [ ] Loading states
- [ ] Form validation
- [ ] Animations

---

## QUICK REFERENCE

**Component Template:**
```bash
# Copy example component as template
cp src/components/ExampleComponent.tsx src/components/MyComponent.tsx
```

**Page Template:**
Use any existing page as template, then customize.

**Testing:**
```bash
npm run dev  # Start dev server
npm run build  # Check for errors
```

**Debugging:**
- React DevTools browser extension
- TypeScript language server (built-in)
- Console logs via `console.log()`

---

## Resources

- **Flutter ↔ React Patterns:** See MIGRATION_GUIDE.md
- **React Best Practices:** https://react.dev/learn
- **TypeScript Guide:** https://www.typescriptlang.org/docs/
- **Zustand Documentation:** https://github.com/pmndrs/zustand
- **Color System:** See `src/utils/theme.ts`

---

## Next: Start Implementing!

1. Read `MIGRATION_GUIDE.md` for detailed patterns
2. Copy `ExampleComponent.tsx` as starting template
3. Start with Phase 2 implementations
4. Reference original Flutter files for logic
5. Use hooks for state management
6. Apply colors via `getThemeColors()`

Good luck! 🚀
