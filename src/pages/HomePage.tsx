import React, { useState, useMemo } from 'react';
import { useDarkMode, useNavigation } from '@/hooks';
import { useAppStore } from '@/store';
import { getThemeColors } from '@/utils/theme';
import { sampleSpaces } from '@/data/fixtures';
import SpaceCard from '@/components/SpaceCard';
import './HomePage.css';

// ─────────────────────────────────────────────────────────────────────────────
// HOME PAGE - Search & Featured Spaces
// (Replaces lib/pages/home_page.dart)
//
// Features:
// - Search bar with live filtering
// - Featured spaces grid
// - Location-based distance
// - Map section (placeholder)
// ─────────────────────────────────────────────────────────────────────────────

const HomePage: React.FC = () => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);

  const [searchQuery, setSearchQuery] = useState('');
  const [searchFocused, setSearchFocused] = useState(false);

  // Filter spaces based on search query
  const filteredSpaces = useMemo(() => {
    if (!searchQuery.trim()) return sampleSpaces;

    const query = searchQuery.toLowerCase();
    return sampleSpaces.filter(
      (space) =>
        space.name.toLowerCase().includes(query) ||
        space.address.toLowerCase().includes(query) ||
        space.types?.some((type) => type.toLowerCase().includes(query))
    );
  }, [searchQuery]);

  // Featured spaces (top rated)
  const featuredSpaces = useMemo(
    () => [...sampleSpaces].sort((a, b) => b.rating - a.rating).slice(0, 3),
    []
  );

  const handleSpaceSelect = (spaceId: string) => {
    // Navigate to space details
  };

  return (
    <div className="home-page">
      {/* Header Section */}
      <header className="home-page__header" style={{ backgroundColor: colors.cardBg }}>
        <div className="home-page__header-content">
          <h1 style={{ color: colors.textPrimary }}>Hotspot</h1>
          <p style={{ color: colors.textSecondary }}>Find your perfect workspace</p>
        </div>
      </header>

      {/* Search Section */}
      <section className="home-page__search-section">
        <div className="home-page__search-container">
          <div
            className={`home-page__search-bar ${searchFocused ? 'focused' : ''}`}
            style={{
              backgroundColor: colors.cardBg,
              borderColor: searchFocused ? '#00C9A7' : colors.borderColor,
            }}
          >
            <span className="home-page__search-icon">🔍</span>
            <input
              type="text"
              placeholder="Search spaces or locations..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onFocus={() => setSearchFocused(true)}
              onBlur={() => setSearchFocused(false)}
              style={{
                color: colors.textPrimary,
                caretColor: '#00C9A7',
              }}
              className="home-page__search-input"
            />
            {searchQuery && (
              <button
                className="home-page__search-clear"
                onClick={() => setSearchQuery('')}
                style={{ color: colors.textSecondary }}
              >
                ✕
              </button>
            )}
          </div>

          {/* Search Suggestions Dropdown */}
          {searchFocused && filteredSpaces.length > 0 && (
            <div
              className="home-page__search-suggestions"
              style={{ backgroundColor: colors.cardBg, borderColor: colors.borderColor }}
            >
              {filteredSpaces.slice(0, 5).map((space) => (
                <button
                  key={space.id}
                  className="home-page__suggestion-item"
                  onClick={() => {
                    setSearchQuery(space.name);
                    setSearchFocused(false);
                    handleSpaceSelect(space.id);
                  }}
                  style={{
                    color: colors.textPrimary,
                    borderBottomColor: colors.borderColor,
                  }}
                >
                  <span>📍</span>
                  <div className="home-page__suggestion-content">
                    <div style={{ fontWeight: 600 }}>{space.name}</div>
                    <div style={{ fontSize: '0.85rem', color: colors.textSecondary }}>
                      {space.address}
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Location Button */}
        <button
          className="home-page__location-btn"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.borderColor,
            color: '#00C9A7',
          }}
          title="Get current location"
        >
          📍
        </button>
      </section>

      {/* Content Section */}
      <main className="home-page__content">
        {searchQuery ? (
          // Search Results
          <>
            <div className="home-page__section-header">
              <h2 style={{ color: colors.textPrimary }}>
                Search Results ({filteredSpaces.length})
              </h2>
            </div>

            {filteredSpaces.length > 0 ? (
              <div className="home-page__spaces-grid">
                {filteredSpaces.map((space) => (
                  <SpaceCard
                    key={space.id}
                    space={space}
                    onSelect={handleSpaceSelect}
                  />
                ))}
              </div>
            ) : (
              <div
                className="home-page__empty-state"
                style={{
                  backgroundColor: colors.cardBg,
                  color: colors.textSecondary,
                }}
              >
                <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>🔍</div>
                <h3 style={{ color: colors.textPrimary }}>No spaces found</h3>
                <p>Try searching for different keywords or locations</p>
              </div>
            )}
          </>
        ) : (
          // Default View
          <>
            {/* Map Placeholder Section */}
            <section
              className="home-page__map-section"
              style={{
                backgroundColor: colors.borderColor,
                borderColor: colors.borderColor,
              }}
            >
              <div
                style={{
                  width: '100%',
                  height: '100%',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: colors.textSecondary,
                  fontSize: '1.125rem',
                }}
              >
                🗺️ Map View (Coming Soon)
              </div>
            </section>

            {/* Featured Spaces Section */}
            <div className="home-page__section-header">
              <h2 style={{ color: colors.textPrimary }}>Featured Spaces</h2>
              <button
                style={{
                  background: 'none',
                  border: 'none',
                  color: '#00C9A7',
                  cursor: 'pointer',
                  fontWeight: 600,
                  fontSize: '0.95rem',
                }}
              >
                See all →
              </button>
            </div>

            <div className="home-page__featured-grid">
              {featuredSpaces.map((space) => (
                <SpaceCard
                  key={space.id}
                  space={space}
                  onSelect={handleSpaceSelect}
                />
              ))}
            </div>

            {/* All Spaces Section */}
            <div className="home-page__section-header">
              <h2 style={{ color: colors.textPrimary }}>All Spaces</h2>
            </div>

            <div className="home-page__spaces-grid">
              {sampleSpaces.map((space) => (
                <SpaceCard
                  key={space.id}
                  space={space}
                  onSelect={handleSpaceSelect}
                />
              ))}
            </div>
          </>
        )}
      </main>
    </div>
  );
};

export default HomePage;
