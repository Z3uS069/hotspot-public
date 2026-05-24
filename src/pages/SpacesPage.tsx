import React, { useState, useMemo } from 'react';
import { useDarkMode } from '@/hooks';
import { useAppStore } from '@/store';
import { getThemeColors } from '@/utils/theme';
import { sampleSpaces } from '@/data/fixtures';
import SpaceCard from '@/components/SpaceCard';
import './SpacesPage.css';

// ─────────────────────────────────────────────────────────────────────────────
// SPACES PAGE
// (Replaces lib/pages/spaces_page.dart)
//
// Shows:
// - Advanced filtering by type, price range, distance
// - Sorting by rating, price, distance, newest
// - Full grid of all spaces
// ─────────────────────────────────────────────────────────────────────────────

const SpacesPage: React.FC = () => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedTypes, setSelectedTypes] = useState<string[]>([]);
  const [priceRange, setPriceRange] = useState({ min: 0, max: 1000 });
  const [sortBy, setSortBy] = useState('rating');

  // Get all unique types from spaces
  const allTypes = useMemo(() => {
    const types = new Set<string>();
    sampleSpaces.forEach((space) => {
      space.types?.forEach((type) => types.add(type));
    });
    return Array.from(types);
  }, []);

  // Filter and sort spaces
  const filteredSpaces = useMemo(() => {
    let results = sampleSpaces.filter((space) => {
      // Search filter
      if (searchQuery) {
        const query = searchQuery.toLowerCase();
        if (
          !space.name.toLowerCase().includes(query) &&
          !space.address.toLowerCase().includes(query)
        ) {
          return false;
        }
      }

      // Type filter
      if (selectedTypes.length > 0) {
        const spaceTypes = space.types || [];
        if (!selectedTypes.some((type) => spaceTypes.includes(type))) {
          return false;
        }
      }

      // Price filter
      if (space.price < priceRange.min || space.price > priceRange.max) {
        return false;
      }

      return true;
    });

    // Sort
    switch (sortBy) {
      case 'rating':
        return results.sort((a, b) => b.rating - a.rating);
      case 'price-low':
        return results.sort((a, b) => a.price - b.price);
      case 'price-high':
        return results.sort((a, b) => b.price - a.price);
      case 'distance':
        return results.sort(
          (a, b) => (a.distanceKm || 0) - (b.distanceKm || 0)
        );
      case 'newest':
        return results;
      default:
        return results;
    }
  }, [searchQuery, selectedTypes, priceRange, sortBy]);

  const handleTypeToggle = (type: string) => {
    setSelectedTypes((prev) =>
      prev.includes(type) ? prev.filter((t) => t !== type) : [...prev, type]
    );
  };

  return (
    <div className="spaces-page" style={{ backgroundColor: colors.bg, color: colors.textPrimary }}>
      {/* Header */}
      <div
        className="spaces-page__header"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        <h1>All Spaces</h1>
        <p style={{ color: colors.textSecondary }}>
          Showing {filteredSpaces.length} spaces
        </p>
      </div>

      {/* Filters Section */}
      <div
        className="spaces-page__filters"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        {/* Search */}
        <div className="spaces-page__filter-group">
          <label style={{ color: colors.textPrimary }}>Search</label>
          <input
            type="text"
            placeholder="Search spaces..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{
              backgroundColor: colors.bg,
              color: colors.textPrimary,
              borderColor: colors.borderColor,
            }}
          />
        </div>

        {/* Type Filter */}
        <div className="spaces-page__filter-group">
          <label style={{ color: colors.textPrimary }}>Type</label>
          <div className="spaces-page__type-chips">
            {allTypes.map((type) => (
              <button
                key={type}
                className={`spaces-page__chip ${
                  selectedTypes.includes(type) ? 'active' : ''
                }`}
                onClick={() => handleTypeToggle(type)}
                style={{
                  backgroundColor: selectedTypes.includes(type)
                    ? '#00C9A7'
                    : colors.surfaceVariant,
                  color: selectedTypes.includes(type)
                    ? '#0B1426'
                    : colors.textSecondary,
                  borderColor: colors.borderColor,
                }}
              >
                {type}
              </button>
            ))}
          </div>
        </div>

        {/* Price Range Filter */}
        <div className="spaces-page__filter-group">
          <label style={{ color: colors.textPrimary }}>
            Price Range: ₹{priceRange.min} - ₹{priceRange.max}
          </label>
          <div className="spaces-page__price-range">
            <input
              type="range"
              min="0"
              max="1000"
              value={priceRange.min}
              onChange={(e) =>
                setPriceRange({
                  ...priceRange,
                  min: Math.min(parseInt(e.target.value), priceRange.max),
                })
              }
              style={{ accentColor: '#00C9A7' }}
            />
            <input
              type="range"
              min="0"
              max="1000"
              value={priceRange.max}
              onChange={(e) =>
                setPriceRange({
                  ...priceRange,
                  max: Math.max(parseInt(e.target.value), priceRange.min),
                })
              }
              style={{ accentColor: '#00C9A7' }}
            />
          </div>
        </div>

        {/* Sort */}
        <div className="spaces-page__filter-group">
          <label style={{ color: colors.textPrimary }}>Sort By</label>
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value)}
            style={{
              backgroundColor: colors.bg,
              color: colors.textPrimary,
              borderColor: colors.borderColor,
            }}
          >
            <option value="rating">Highest Rated</option>
            <option value="price-low">Price: Low to High</option>
            <option value="price-high">Price: High to Low</option>
            <option value="distance">Nearest First</option>
            <option value="newest">Newest</option>
          </select>
        </div>
      </div>

      {/* Spaces Grid */}
      <div className="spaces-page__content">
        {filteredSpaces.length > 0 ? (
          <div className="spaces-page__grid">
            {filteredSpaces.map((space) => (
              <SpaceCard key={space.id} space={space} />
            ))}
          </div>
        ) : (
          <div
            className="spaces-page__empty"
            style={{ color: colors.textSecondary }}
          >
            <p>No spaces found matching your filters.</p>
            <button
              onClick={() => {
                setSearchQuery('');
                setSelectedTypes([]);
                setPriceRange({ min: 0, max: 1000 });
                setSortBy('rating');
              }}
              style={{
                backgroundColor: '#00C9A7',
                color: '#0B1426',
                border: 'none',
                padding: '0.75rem 1.5rem',
                borderRadius: '0.5rem',
                cursor: 'pointer',
                marginTop: '1rem',
              }}
            >
              Reset Filters
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default SpacesPage;
