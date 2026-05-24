import React, { useMemo } from 'react';
import { useDarkMode } from '@/hooks';
import { getThemeColors } from '@/utils/theme';
import { sampleSpaces } from '@/data/fixtures';
import SpaceCard from '@/components/SpaceCard';
import './SavedPage.css';

// ─────────────────────────────────────────────────────────────────────────────
// SAVED PAGE
// (Replaces lib/pages/saved_page.dart)
//
// Shows:
// - List of saved/favorited spaces
// - Empty state if no saves
// - Sorting options
// ─────────────────────────────────────────────────────────────────────────────

const SavedPage: React.FC = () => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);

  // Get saved spaces (those marked with isFavorite)
  const savedSpaces = useMemo(() => {
    return sampleSpaces.filter((space) => space.isFavorite);
  }, []);

  return (
    <div className="saved-page" style={{ backgroundColor: colors.bg, color: colors.textPrimary }}>
      {/* Header */}
      <div
        className="saved-page__header"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        <h1>Saved Spaces</h1>
        <p style={{ color: colors.textSecondary }}>
          {savedSpaces.length} space{savedSpaces.length !== 1 ? 's' : ''}
        </p>
      </div>

      {/* Content */}
      <div className="saved-page__content">
        {savedSpaces.length > 0 ? (
          <div className="saved-page__grid">
            {savedSpaces.map((space) => (
              <SpaceCard key={space.id} space={space} />
            ))}
          </div>
        ) : (
          <div
            className="saved-page__empty"
            style={{
              color: colors.textSecondary,
              backgroundColor: colors.cardBg,
              borderColor: colors.borderColor,
            }}
          >
            <div className="saved-page__empty-icon">❤️</div>
            <h2 style={{ color: colors.textPrimary }}>No Saved Spaces</h2>
            <p>
              Start exploring and save your favorite spaces to revisit them
              later.
            </p>
            <button
              onClick={() => alert('Navigating to spaces...')}
              style={{
                backgroundColor: '#00C9A7',
                color: '#0B1426',
                border: 'none',
                padding: '0.75rem 1.5rem',
                borderRadius: '0.5rem',
                cursor: 'pointer',
                marginTop: '1rem',
                fontWeight: 600,
              }}
            >
              Explore Spaces
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default SavedPage;
