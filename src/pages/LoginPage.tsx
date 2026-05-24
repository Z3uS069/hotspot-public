import React, { useState } from 'react';
import { useNavigation, useDarkMode } from '@/hooks';
import { AppScreen, AppRole } from '@/types/app';
import { getThemeColors } from '@/utils/theme';

interface LoginPageProps {
  role: AppRole;
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN PAGE
// (Replaces lib/pages/login_page.dart)
// ─────────────────────────────────────────────────────────────────────────────

const LoginPage: React.FC<LoginPageProps> = ({ role }) => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);
  const { setScreen } = useNavigation();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = async () => {
    setIsLoading(true);
    // TODO: Integrate with backend API
    setTimeout(() => {
      setIsLoading(false);
      // Navigate to appropriate app screen
      setScreen(role === AppRole.Admin ? AppScreen.AdminApp : AppScreen.UserApp);
    }, 1500);
  };

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '100vh',
        padding: '2rem',
      }}
    >
      <div
        style={{
          width: '100%',
          maxWidth: '400px',
          padding: '2rem',
          backgroundColor: colors.cardBg,
          borderRadius: '1rem',
          border: `1px solid ${colors.borderColor}`,
        }}
      >
        <h1 style={{ fontSize: '1.875rem', marginBottom: '0.5rem', fontWeight: 'bold' }}>
          Welcome back
        </h1>
        <p style={{ color: colors.textSecondary, marginBottom: '2rem' }}>
          Sign in to your {role === AppRole.Admin ? 'admin' : 'user'} account
        </p>

        {/* Email Input */}
        <div style={{ marginBottom: '1rem' }}>
          <label
            style={{
              display: 'block',
              marginBottom: '0.5rem',
              color: colors.textPrimary,
              fontWeight: '500',
            }}
          >
            Email
          </label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            style={{
              width: '100%',
              padding: '0.75rem',
              borderRadius: '0.5rem',
              border: `1px solid ${colors.borderColor}`,
              backgroundColor: colors.bg,
              color: colors.textPrimary,
              fontSize: '1rem',
              transition: 'border-color 0.3s ease',
            }}
            onFocus={(e) => (e.currentTarget.style.borderColor = '#00C9A7')}
            onBlur={(e) => (e.currentTarget.style.borderColor = colors.borderColor)}
          />
        </div>

        {/* Password Input */}
        <div style={{ marginBottom: '2rem' }}>
          <label
            style={{
              display: 'block',
              marginBottom: '0.5rem',
              color: colors.textPrimary,
              fontWeight: '500',
            }}
          >
            Password
          </label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            style={{
              width: '100%',
              padding: '0.75rem',
              borderRadius: '0.5rem',
              border: `1px solid ${colors.borderColor}`,
              backgroundColor: colors.bg,
              color: colors.textPrimary,
              fontSize: '1rem',
              transition: 'border-color 0.3s ease',
            }}
            onFocus={(e) => (e.currentTarget.style.borderColor = '#00C9A7')}
            onBlur={(e) => (e.currentTarget.style.borderColor = colors.borderColor)}
          />
        </div>

        {/* Login Button */}
        <button
          onClick={handleLogin}
          disabled={isLoading || !email || !password}
          style={{
            width: '100%',
            padding: '0.75rem',
            borderRadius: '0.5rem',
            border: 'none',
            backgroundColor: '#00C9A7',
            color: '#0B1426',
            fontWeight: 'bold',
            fontSize: '1rem',
            cursor: isLoading ? 'not-allowed' : 'pointer',
            opacity: isLoading ? 0.7 : 1,
            transition: 'all 0.3s ease',
            marginBottom: '1rem',
          }}
          onMouseEnter={(e) => {
            if (!isLoading) e.currentTarget.style.opacity = '0.9';
          }}
          onMouseLeave={(e) => {
            if (!isLoading) e.currentTarget.style.opacity = '1';
          }}
        >
          {isLoading ? 'Signing in...' : 'Sign In'}
        </button>

        {/* Switch to Signup */}
        <p style={{ textAlign: 'center', color: colors.textSecondary }}>
          Don't have an account?{' '}
          <button
            onClick={() => setScreen(AppScreen.Signup)}
            style={{
              background: 'none',
              border: 'none',
              color: '#00C9A7',
              cursor: 'pointer',
              fontWeight: 'bold',
              textDecoration: 'underline',
            }}
          >
            Sign up
          </button>
        </p>
      </div>
    </div>
  );
};

export default LoginPage;
