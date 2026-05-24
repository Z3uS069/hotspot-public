import React, { useEffect } from 'react';
import { useDarkMode, useNavigation } from '@/hooks';
import { useAppStore } from '@/store';
import { AppScreen, AppRole } from '@/types/app';
import { getThemeColors } from '@/utils/theme';
import './App.css';

// Pages
import RoleSelectionPage from '@/pages/RoleSelectionPage';
import LoginPage from '@/pages/LoginPage';
import SignupPage from '@/pages/SignupPage';
import UserAppShell from '@/pages/UserAppShell';
import SpaceDetailsPage from '@/pages/SpaceDetailsPage';
import AdminAppShell from '@/pages/AdminAppShell';

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND DECORATIVE BLOBS (equivalent to Flutter's _BackgroundBubbles)
// ─────────────────────────────────────────────────────────────────────────────

const BackgroundBlobs: React.FC<{ isDarkMode: boolean; isAdmin: boolean }> = ({
  isDarkMode,
  isAdmin,
}) => {
  const blobColor1 = isAdmin ? '#8B5CF6' : '#00C9A7';
  const blobColor2 = isAdmin ? '#6366F1' : '#4DD0E1';

  return (
    <div className="background-blobs">
      <div
        className="blob blob-1"
        style={{
          background: `radial-gradient(circle, ${blobColor1}10 0%, ${blobColor1}00 70%)`,
        }}
      />
      <div
        className="blob blob-2"
        style={{
          background: `radial-gradient(circle, ${blobColor2}10 0%, ${blobColor2}00 70%)`,
        }}
      />
      <div
        className="blob blob-3"
        style={{
          background: `radial-gradient(circle, ${blobColor1}10 0%, ${blobColor1}00 70%)`,
        }}
      />
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN ROUTER (equivalent to Flutter's _buildScreen)
// ─────────────────────────────────────────────────────────────────────────────

const ScreenRouter: React.FC = () => {
  const screen = useAppStore((state) => state.screen);
  const role = useAppStore((state) => state.role);
  const spaceDetailsId = useAppStore((state) => state.spaceDetailsId);
  const setScreen = useAppStore((state) => state.setScreen);
  const setSpaceDetailsId = useAppStore((state) => state.setSpaceDetailsId);

  switch (screen) {
    case AppScreen.RoleSelect:
      return <RoleSelectionPage />;
    case AppScreen.Signup:
      return <SignupPage role={role || AppRole.User} />;
    case AppScreen.Login:
      return <LoginPage role={role || AppRole.User} />;
    case AppScreen.SpaceSetup:
      return <AdminAppShell />;
    case AppScreen.UserApp:
      return <UserAppShell />;
    case AppScreen.SpaceDetails:
      return (
        <SpaceDetailsPage
          spaceId={spaceDetailsId || '1'}
          onBack={() => {
            setSpaceDetailsId(null);
            setScreen(AppScreen.UserApp);
          }}
        />
      );
    case AppScreen.AdminApp:
      return <AdminAppShell />;
    default:
      return <RoleSelectionPage />;
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// MAIN APP COMPONENT (equivalent to Flutter's MyApp + AppShell)
// ─────────────────────────────────────────────────────────────────────────────

const App: React.FC = () => {
  const { isDarkMode } = useDarkMode();
  const { screen, role } = useNavigation();
  const colors = getThemeColors(isDarkMode);

  const isAdmin = role === AppRole.Admin || screen === AppScreen.AdminApp || screen === AppScreen.SpaceSetup;

  useEffect(() => {
    // Update document style
    document.documentElement.style.backgroundColor = colors.bg;
    document.documentElement.style.color = colors.textPrimary;
  }, [colors]);

  return (
    <div
      className="app"
      style={{
        backgroundColor: colors.bg,
        color: colors.textPrimary,
        minHeight: '100vh',
        transition: 'background-color 0.3s ease, color 0.3s ease',
      }}
    >
      {/* Decorative background blobs */}
      <BackgroundBlobs isDarkMode={isDarkMode} isAdmin={isAdmin} />

      {/* Screen router with fade transition */}
      <div className="screen-container">
        <ScreenRouter />
      </div>
    </div>
  );
};

export default App;
