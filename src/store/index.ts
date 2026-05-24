import { create } from 'zustand';
import { AppState, AppScreen, AppRole, AppTab } from '@/types/app';

// ─────────────────────────────────────────────────────────────────────────────
// ZUSTAND STORE (replaces Flutter's Provider)
// ─────────────────────────────────────────────────────────────────────────────

export const useAppStore = create<AppState>((set) => ({
  // ── Theme state ───────────────────────────────────────────────────────────
  isDarkMode: true,
  toggleTheme: () => set((state) => ({ isDarkMode: !state.isDarkMode })),
  setDarkMode: (value: boolean) => set({ isDarkMode: value }),

  // ── Navigation state ───────────────────────────────────────────────────────
  screen: AppScreen.RoleSelect,
  setScreen: (screen: AppScreen) => set({ screen }),

  role: null,
  setRole: (role: AppRole) => set({ role }),

  activeTab: AppTab.Map,
  setActiveTab: (tab: AppTab) => set({ activeTab: tab }),

  // ── Overlay flags ──────────────────────────────────────────────────────────
  selectedSpaceId: null,
  selectSpace: (id: string) => set({ selectedSpaceId: id }),

  spaceDetailsId: null,
  setSpaceDetailsId: (id: string | null) => set({ spaceDetailsId: id }),

  isBookingFormOpen: false,
  setIsBookingFormOpen: (open: boolean) => set({ isBookingFormOpen: open }),

  isDirectionsOpen: false,
  setIsDirectionsOpen: (open: boolean) => set({ isDirectionsOpen: open }),

  isProfileOpen: false,
  setIsProfileOpen: (open: boolean) => set({ isProfileOpen: open }),

  isNotificationOpen: false,
  setIsNotificationOpen: (open: boolean) => set({ isNotificationOpen: open }),
}));
