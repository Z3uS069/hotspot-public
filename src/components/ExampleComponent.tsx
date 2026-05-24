import React from 'react';
import { useDarkMode } from '@/hooks';
import { getThemeColors } from '@/utils/theme';

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT TEMPLATE EXAMPLE
// Copy this template and customize for new components
// ─────────────────────────────────────────────────────────────────────────────

interface ExampleComponentProps {
  title: string;
  description?: string;
  onClick?: () => void;
}

/**
 * ExampleComponent
 * 
 * A template component demonstrating best practices:
 * - TypeScript interfaces for props
 * - Dark mode support via useDarkMode() hook
 * - Theme color system
 * - Proper accessibility
 * - Responsive design
 * 
 * Flutter Equivalent: lib/widgets/example_widget.dart
 */
const ExampleComponent: React.FC<ExampleComponentProps> = ({
  title,
  description,
  onClick,
}) => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);

  return (
    <div
      onClick={onClick}
      style={{
        backgroundColor: colors.cardBg,
        border: `1px solid ${colors.borderColor}`,
        borderRadius: '0.75rem',
        padding: '1.5rem',
        cursor: onClick ? 'pointer' : 'default',
        transition: 'all 0.3s ease',
        textDecoration: 'none',
      }}
      role="button"
      tabIndex={onClick ? 0 : -1}
      onKeyDown={(e) => {
        if (onClick && (e.key === 'Enter' || e.key === ' ')) {
          e.preventDefault();
          onClick();
        }
      }}
    >
      <h3 style={{ color: colors.textPrimary, marginBottom: '0.5rem' }}>
        {title}
      </h3>
      {description && (
        <p style={{ color: colors.textSecondary, margin: 0, fontSize: '0.95rem' }}>
          {description}
        </p>
      )}
    </div>
  );
};

export default ExampleComponent;

// ─────────────────────────────────────────────────────────────────────────────
// USAGE EXAMPLE
// ─────────────────────────────────────────────────────────────────────────────

/**
 * <ExampleComponent
 *   title="Space Name"
 *   description="123 Main St, Anytown USA"
 *   onClick={() => console.log('Clicked')}
 * />
 */
