// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

export enum AppScreen {
  RoleSelect = 'roleSelect',
  Signup = 'signup',
  Login = 'login',
  SpaceSetup = 'spaceSetup',
  UserApp = 'userApp',
  SpaceDetails = 'spaceDetails',
  AdminApp = 'adminApp',
}

export enum AppRole {
  User = 'user',
  Admin = 'admin',
}

export enum AppTab {
  Map = 'map',
  Space = 'space',
  Activity = 'activity',
  Saved = 'saved',
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME TYPES
// ─────────────────────────────────────────────────────────────────────────────

export interface AppColors {
  // Dark mode colours
  appBgDark: string;
  appCardDark: string;
  appBorderDark: string;

  // Light mode colours
  appBgLight: string;
  appCardLight: string;
  appBorderLight: string;

  // Shared accent colours
  appAccent: string;
  appAccent2: string;

  // Admin theme
  adminBg: string;
  adminCard: string;
  adminBorder: string;
  adminBgLight: string;
  adminCardLight: string;
  adminBorderLight: string;
  adminAccent: string;
  adminAccent2: string;

  // Text colours
  white: string;
  grey400: string;
  grey500: string;
  red400: string;
  orange400: string;
  orange500: string;
  lightTextPrimary: string;
  lightTextSecondary: string;
  lightTextMuted: string;
}

// ─────────────────────────────────────────────────────────────────────────────
// APP STATE
// ─────────────────────────────────────────────────────────────────────────────

export interface AppState {
  // Theme
  isDarkMode: boolean;
  toggleTheme: () => void;
  setDarkMode: (value: boolean) => void;

  // Navigation
  screen: AppScreen;
  setScreen: (screen: AppScreen) => void;
  role: AppRole | null;
  setRole: (role: AppRole) => void;
  activeTab: AppTab;
  setActiveTab: (tab: AppTab) => void;

  // Overlays
  selectedSpaceId: string | null;
  selectSpace: (id: string) => void;
  spaceDetailsId: string | null;
  setSpaceDetailsId: (id: string | null) => void;
  isBookingFormOpen: boolean;
  setIsBookingFormOpen: (open: boolean) => void;
  isDirectionsOpen: boolean;
  setIsDirectionsOpen: (open: boolean) => void;
  isProfileOpen: boolean;
  setIsProfileOpen: (open: boolean) => void;
  isNotificationOpen: boolean;
  setIsNotificationOpen: (open: boolean) => void;
}
