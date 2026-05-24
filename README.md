# Hotspot Web Project Setup

A responsive web application conversion of the Hotspot Flutter project using React + TypeScript.

## Features

✅ **Multi-role authentication** - User and Admin roles  
✅ **Dark/Light theme** - System-aware theme switching  
✅ **Responsive design** - Mobile-first approach  
✅ **Type-safe** - Full TypeScript support  
✅ **State management** - Zustand for global state  
✅ **Modern tooling** - Vite, React 18, TypeScript 5  

## Getting Started

### Prerequisites
- Node.js 16+ 
- npm or yarn

### Installation

```bash
# Navigate to project directory
cd hotspot-web

# Install dependencies
npm install

# Start development server
npm run dev

# Open browser to http://localhost:3000
```

### Build for Production

```bash
npm run build
npm run preview
```

## Project Structure

**Core Files:**
- `src/App.tsx` - Main app component with screen routing
- `src/store/index.ts` - Global state management (Zustand)
- `src/utils/theme.ts` - Theme colors and helpers
- `src/hooks/index.ts` - Custom React hooks

**Pages** (one per Flutter screen):
- `src/pages/RoleSelectionPage.tsx` - Role selection
- `src/pages/LoginPage.tsx` - User login
- `src/pages/SignupPage.tsx` - User registration
- `src/pages/SpaceSetupPage.tsx` - Admin space setup
- `src/pages/UserAppShell.tsx` - User app main shell
- `src/pages/AdminDashboardPage.tsx` - Admin dashboard

**Components** (UI widgets):
- `src/components/` - Reusable UI components (stubs)

**Models & Types:**
- `src/models/index.ts` - Data models
- `src/types/app.ts` - TypeScript type definitions

## State Management (Zustand)

Instead of Flutter's `Provider` pattern, this project uses Zustand for state management:

```typescript
// Access state
const isDarkMode = useAppStore((state) => state.isDarkMode);

// Update state
const { toggleTheme } = useAppStore((state) => ({
  toggleTheme: state.toggleTheme,
}));

// Or use custom hooks
const { isDarkMode, toggleTheme } = useDarkMode();
```

## Theming

Theme colors match the Flutter project:

```typescript
// Get theme-aware colors
const colors = getThemeColors(isDarkMode);

// Usage in component
<div style={{ backgroundColor: colors.bg, color: colors.textPrimary }}>
  Content
</div>
```

## Navigation Flow

```
RoleSelection → Signup/Login → UserApp/AdminApp
```

The app uses a simple state-based routing system via `AppProvider`:
- `screen` - Current screen to display
- `role` - User or Admin role
- `activeTab` - Active tab in tab navigation

## Key Equivalencies

| Flutter | React |
|---------|-------|
| `MaterialApp` | React app wrapper |
| `Provider` + `ChangeNotifier` | Zustand store |
| `Scaffold` | Layout component |
| `AppBar` | Header component |
| `FloatingActionButton` | Button component |
| `TextField` | Input element |
| `GestureDetector` | Event handlers |
| `StatelessWidget` | Functional component |
| `StatefulWidget` | Component with hooks |
| `Consumer` | Hook selectors |

## Development Workflow

1. **Create new page**: Add file to `src/pages/`
2. **Create new component**: Add file to `src/components/`
3. **Add state**: Update `src/store/index.ts`
4. **Update types**: Edit `src/types/app.ts`
5. **Apply styling**: Use `getThemeColors()` for consistency

## Next Steps

See [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) for detailed Flutter → React mapping and implementation priorities.

## Dependencies

- **React 18** - UI framework
- **TypeScript** - Type safety
- **Zustand** - State management
- **Vite** - Build tool
- **qrcode.react** - QR code generation
- **react-router-dom** - Routing (optional)
- **lucide-react** - Icons (optional)

## Browser Support

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Mobile browsers (iOS Safari 14+, Chrome Android)

## Performance Tips

- Use React DevTools to check re-renders
- Memoize expensive components with `React.memo()`
- Use Zustand selectors to avoid unnecessary re-renders
- Lazy load pages with `React.lazy()` and `Suspense`

## Troubleshooting

**Port 3000 already in use?**
```bash
# Use different port
npm run dev -- --port 3001
```

**Module not found errors?**
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

**TypeScript errors?**
- Check `tsconfig.json` paths are configured correctly
- Ensure all imports use correct file extensions

## Resources

- [React Documentation](https://react.dev)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Zustand Documentation](https://github.com/pmndrs/zustand)
- [Vite Guide](https://vitejs.dev/guide/)
- [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) - Detailed Flutter to React mapping

---

Happy coding! 🚀
