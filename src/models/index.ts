// ─────────────────────────────────────────────────────────────────────────────
// SPACE MODEL (from lib/models/space_model.dart)
// ─────────────────────────────────────────────────────────────────────────────

export interface SpaceModel {
  id: string;
  name: string;
  address: string;
  description: string;
  imageUrl: string;
  price: number;
  rating: number;
  reviewCount: number;
  latitude: number;
  longitude: number;
  amenities: string[];
  capacity: number;
  availability: {
    startTime: string;
    endTime: string;
  };
  isFavorite: boolean;
  tag?: string;
  types?: string[];
  distanceKm?: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING MODEL (from lib/models/booking_model.dart)
// ─────────────────────────────────────────────────────────────────────────────

export enum BookingStatus {
  Pending = 'pending',
  Confirmed = 'confirmed',
  Active = 'active',
  Completed = 'completed',
  Cancelled = 'cancelled',
}

export interface BookingModel {
  id: string;
  spaceId: string;
  userId: string;
  spaceName: string;
  status: BookingStatus;
  checkInTime: string;
  checkOutTime: string;
  totalPrice: number;
  numberOfPeople: number;
  specialRequests?: string;
  createdAt: string;
  updatedAt: string;
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW MODEL (from lib/models/review_model.dart)
// ─────────────────────────────────────────────────────────────────────────────

export interface ReviewModel {
  id: string;
  spaceId: string;
  userId: string;
  userName: string;
  userAvatar: string;
  rating: number;
  comment: string;
  createdAt: string;
  helpfulCount: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// USER MODEL
// ─────────────────────────────────────────────────────────────────────────────

export interface UserModel {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  role: 'user' | 'admin';
  phone?: string;
  createdAt: string;
}
