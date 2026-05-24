import { useAppStore } from '@/store';
import { useEffect } from 'react';

// ─────────────────────────────────────────────────────────────────────────────
// DARK MODE HOOK
// ─────────────────────────────────────────────────────────────────────────────

export const useDarkMode = () => {
  const isDarkMode = useAppStore((state) => state.isDarkMode);
  const toggleTheme = useAppStore((state) => state.toggleTheme);
  const setDarkMode = useAppStore((state) => state.setDarkMode);

  // Update document class and localStorage when theme changes
  useEffect(() => {
    const root = document.documentElement;
    const body = document.body;

    if (isDarkMode) {
      body.classList.remove('light');
      body.classList.add('dark');
      root.style.colorScheme = 'dark';
    } else {
      body.classList.remove('dark');
      body.classList.add('light');
      root.style.colorScheme = 'light';
    }

    // Persist preference
    localStorage.setItem('theme', isDarkMode ? 'dark' : 'light');
  }, [isDarkMode]);

  // Load theme preference on mount
  useEffect(() => {
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'light') {
      setDarkMode(false);
    } else if (savedTheme === 'dark') {
      setDarkMode(true);
    } else {
      // Use system preference
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      setDarkMode(prefersDark);
    }
  }, [setDarkMode]);

  return { isDarkMode, toggleTheme, setDarkMode };
};

// ─────────────────────────────────────────────────────────────────────────────
// NAVIGATION HOOK
// ─────────────────────────────────────────────────────────────────────────────

export const useNavigation = () => {
  const screen = useAppStore((state) => state.screen);
  const setScreen = useAppStore((state) => state.setScreen);
  const role = useAppStore((state) => state.role);
  const setRole = useAppStore((state) => state.setRole);
  const activeTab = useAppStore((state) => state.activeTab);
  const setActiveTab = useAppStore((state) => state.setActiveTab);

  return {
    screen,
    setScreen,
    role,
    setRole,
    activeTab,
    setActiveTab,
  };
};

// ─────────────────────────────────────────────────────────────────────────────
// OVERLAY HOOK
// ─────────────────────────────────────────────────────────────────────────────

export const useOverlays = () => {
  const selectedSpaceId = useAppStore((state) => state.selectedSpaceId);
  const selectSpace = useAppStore((state) => state.selectSpace);
  const isBookingFormOpen = useAppStore((state) => state.isBookingFormOpen);
  const setIsBookingFormOpen = useAppStore((state) => state.setIsBookingFormOpen);
  const isDirectionsOpen = useAppStore((state) => state.isDirectionsOpen);
  const setIsDirectionsOpen = useAppStore((state) => state.setIsDirectionsOpen);
  const isProfileOpen = useAppStore((state) => state.isProfileOpen);
  const setIsProfileOpen = useAppStore((state) => state.setIsProfileOpen);
  const isNotificationOpen = useAppStore((state) => state.isNotificationOpen);
  const setIsNotificationOpen = useAppStore((state) => state.setIsNotificationOpen);

  return {
    selectedSpaceId,
    selectSpace,
    isBookingFormOpen,
    setIsBookingFormOpen,
    isDirectionsOpen,
    setIsDirectionsOpen,
    isProfileOpen,
    setIsProfileOpen,
    isNotificationOpen,
    setIsNotificationOpen,
  };
};
