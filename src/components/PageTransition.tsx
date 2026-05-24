import React, { ReactNode } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

// ─────────────────────────────────────────────────────────────────────────────
// PAGE TRANSITION COMPONENT
// (Wraps pages with entrance/exit animations)
//
// Features:
// - Fade in/out animations
// - Slide animations
// - Staggered animations for lists
// ─────────────────────────────────────────────────────────────────────────────

interface PageTransitionProps {
  children: ReactNode;
  delay?: number;
  direction?: 'up' | 'down' | 'left' | 'right';
}

export const PageTransition: React.FC<PageTransitionProps> = ({
  children,
  delay = 0,
  direction = 'up',
}) => {
  const getInitial = () => {
    const offset = 30;
    switch (direction) {
      case 'up':
        return { opacity: 0, y: offset };
      case 'down':
        return { opacity: 0, y: -offset };
      case 'left':
        return { opacity: 0, x: offset };
      case 'right':
        return { opacity: 0, x: -offset };
      default:
        return { opacity: 0, y: offset };
    }
  };

  const getExit = () => {
    const offset = 30;
    switch (direction) {
      case 'up':
        return { opacity: 0, y: -offset };
      case 'down':
        return { opacity: 0, y: offset };
      case 'left':
        return { opacity: 0, x: -offset };
      case 'right':
        return { opacity: 0, x: offset };
      default:
        return { opacity: 0, y: -offset };
    }
  };

  return (
    <motion.div
      initial={getInitial()}
      animate={{ opacity: 1, x: 0, y: 0 }}
      exit={getExit()}
      transition={{
        duration: 0.5,
        ease: 'easeInOut',
        delay,
      }}
    >
      {children}
    </motion.div>
  );
};

// ─────────────────────────────────────────────────────────────────────────────
// LIST STAGGER CONTAINER (for animating list items with stagger effect)
// ─────────────────────────────────────────────────────────────────────────────

interface StaggerContainerProps {
  children: ReactNode;
  staggerDelay?: number;
}

export const StaggerContainer: React.FC<StaggerContainerProps> = ({
  children,
  staggerDelay = 0.1,
}) => {
  return (
    <motion.div
      initial="hidden"
      animate="visible"
      variants={{
        hidden: { opacity: 0 },
        visible: {
          opacity: 1,
          transition: {
            staggerChildren: staggerDelay,
            delayChildren: 0.2,
          },
        },
      }}
    >
      {children}
    </motion.div>
  );
};

// ─────────────────────────────────────────────────────────────────────────────
// STAGGER ITEM (child of StaggerContainer)
// ─────────────────────────────────────────────────────────────────────────────

interface StaggerItemProps {
  children: ReactNode;
}

export const StaggerItem: React.FC<StaggerItemProps> = ({ children }) => {
  return (
    <motion.div
      variants={{
        hidden: { opacity: 0, y: 20 },
        visible: { opacity: 1, y: 0 },
      }}
      transition={{ duration: 0.4 }}
    >
      {children}
    </motion.div>
  );
};

// ─────────────────────────────────────────────────────────────────────────────
// FADE TRANSITION (simple fade in/out)
// ─────────────────────────────────────────────────────────────────────────────

interface FadeTransitionProps {
  children: ReactNode;
  duration?: number;
}

export const FadeTransition: React.FC<FadeTransitionProps> = ({
  children,
  duration = 0.3,
}) => {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration }}
    >
      {children}
    </motion.div>
  );
};

// ─────────────────────────────────────────────────────────────────────────────
// SCALE ANIMATION (for card hover effects)
// ─────────────────────────────────────────────────────────────────────────────

interface ScaleAnimationProps {
  children: ReactNode;
  scale?: number;
  duration?: number;
}

export const ScaleAnimation: React.FC<ScaleAnimationProps> = ({
  children,
  scale = 1.05,
  duration = 0.3,
}) => {
  return (
    <motion.div whileHover={{ scale }} transition={{ duration }}>
      {children}
    </motion.div>
  );
};

export default PageTransition;
