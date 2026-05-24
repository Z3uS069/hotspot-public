import React, { useState } from 'react';
import { useNavigation, useDarkMode } from '@/hooks';
import { AppScreen, AppRole } from '@/types/app';
import { getThemeColors } from '@/utils/theme';

interface SignupPageProps {
  role: AppRole;
}

// ─────────────────────────────────────────────────────────────────────────────
// SIGNUP PAGE
// (Replaces lib/pages/signup_page.dart)
// ─────────────────────────────────────────────────────────────────────────────

const SignupPage: React.FC<SignupPageProps> = ({ role }) => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);
  const { setScreen } = useNavigation();

  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSignup = async () => {
    if (password !== confirmPassword) {
      alert('Passwords do not match');
      return;
    }

    setIsLoading(true);
    // TODO: Integrate with backend API
    setTimeout(() => {
      setIsLoading(false);
      if (role === AppRole.Admin) {
        setScreen(AppScreen.SpaceSetup);
      } else {
        setScreen(AppScreen.UserApp);
      }
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
          Create Account
        </h1>
        <p style={{ color: colors.textSecondary, marginBottom: '2rem' }}>
          Join Hotspot as a {role === AppRole.Admin ? 'space owner' : 'user'}
        </p>

        {/* Name Input */}
        <div style={{ marginBottom: '1rem' }}>
          <label
            style={{
              display: 'block',
              marginBottom: '0.5rem',
              color: colors.textPrimary,
              fontWeight: '500',
            }}
          >
            Full Name
          </label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="John Doe"
            style={{
              width: '100%',
              padding: '0.75rem',
              borderRadius: '0.5rem',
              border: `1px solid ${colors.borderColor}`,
              backgroundColor: colors.bg,
              color: colors.textPrimary,
              fontSize: '1rem',
            }}
          />
        </div>

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
            }}
          />
        </div>

        {/* Password Input */}
        <div style={{ marginBottom: '1rem' }}>
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
            }}
          />
        </div>

        {/* Confirm Password Input */}
        <div style={{ marginBottom: '2rem' }}>
          <label
            style={{
              display: 'block',
              marginBottom: '0.5rem',
              color: colors.textPrimary,
              fontWeight: '500',
            }}
          >
            Confirm Password
          </label>
          <input
            type="password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            placeholder="••••••••"
            style={{
              width: '100%',
              padding: '0.75rem',
              borderRadius: '0.5rem',
              border: `1px solid ${colors.borderColor}`,
              backgroundColor: colors.bg,
              color: colors.textPrimary,
              fontSize: '1rem',
            }}
          />
        </div>

        {/* Signup Button */}
        <button
          onClick={handleSignup}
          disabled={isLoading || !name || !email || !password || !confirmPassword}
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
        >
          {isLoading ? 'Creating Account...' : 'Sign Up'}
        </button>

        {/* Switch to Login */}
        <p style={{ textAlign: 'center', color: colors.textSecondary }}>
          Already have an account?{' '}
          <button
            onClick={() => setScreen(AppScreen.Login)}
            style={{
              background: 'none',
              border: 'none',
              color: '#00C9A7',
              cursor: 'pointer',
              fontWeight: 'bold',
              textDecoration: 'underline',
            }}
          >
            Sign in
          </button>
        </p>
      </div>
    </div>
  );
};

export default SignupPage;
