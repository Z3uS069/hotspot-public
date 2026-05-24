import { z } from 'zod';

// ─────────────────────────────────────────────────────────────────────────────
// FORM VALIDATION SCHEMAS
// (Using Zod for type-safe validation)
// ─────────────────────────────────────────────────────────────────────────────

// Login Schema
export const LoginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});

export type LoginFormData = z.infer<typeof LoginSchema>;

// Signup Schema
export const SignupSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),
  confirmPassword: z.string(),
  acceptTerms: z.boolean().refine((val) => val === true, {
    message: 'You must accept the terms and conditions',
  }),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
});

export type SignupFormData = z.infer<typeof SignupSchema>;

// Space Setup Schema
export const SpaceSetupSchema = z.object({
  name: z.string().min(3, 'Space name must be at least 3 characters'),
  address: z.string().min(5, 'Address must be at least 5 characters'),
  description: z.string().min(10, 'Description must be at least 10 characters'),
  price: z.number().min(1, 'Price must be greater than 0'),
  capacity: z.number().min(1, 'Capacity must be at least 1'),
  imageUrl: z.string().url('Invalid image URL'),
  amenities: z.array(z.string()).min(1, 'Select at least one amenity'),
  startTime: z.string().regex(/^\d{2}:\d{2}$/, 'Invalid time format'),
  endTime: z.string().regex(/^\d{2}:\d{2}$/, 'Invalid time format'),
}).refine(
  (data) => {
    const [startHour, startMin] = data.startTime.split(':').map(Number);
    const [endHour, endMin] = data.endTime.split(':').map(Number);
    const startTotalMin = startHour * 60 + startMin;
    const endTotalMin = endHour * 60 + endMin;
    return startTotalMin < endTotalMin;
  },
  {
    message: 'Opening time must be before closing time',
    path: ['endTime'],
  }
);

export type SpaceSetupFormData = z.infer<typeof SpaceSetupSchema>;

// Booking Schema
export const BookingSchema = z.object({
  date: z.string().min(1, 'Date is required'),
  startTime: z.string().min(1, 'Start time is required'),
  endTime: z.string().min(1, 'End time is required'),
  numberOfPeople: z.number().min(1, 'At least 1 person required'),
  specialRequests: z.string().optional(),
  agreeTerms: z.boolean().refine((val) => val === true, {
    message: 'You must agree to the terms',
  }),
});

export type BookingFormData = z.infer<typeof BookingSchema>;

// Profile Edit Schema
export const ProfileEditSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  phone: z.string().regex(/^\d{10}$/, 'Phone must be 10 digits'),
});

export type ProfileEditFormData = z.infer<typeof ProfileEditSchema>;

// ─────────────────────────────────────────────────────────────────────────────
// VALIDATION ERROR FORMATTER
// ─────────────────────────────────────────────────────────────────────────────

export const formatValidationError = (
  error: z.ZodError
): Record<string, string> => {
  const errors: Record<string, string> = {};
  error.errors.forEach((err) => {
    const path = err.path.join('.');
    errors[path] = err.message;
  });
  return errors;
};

// ─────────────────────────────────────────────────────────────────────────────
// ASYNC VALIDATION HELPERS
// ─────────────────────────────────────────────────────────────────────────────

// Check if email already exists (mock implementation)
export const checkEmailExists = async (email: string): Promise<boolean> => {
  // Simulating API call
  await new Promise((resolve) => setTimeout(resolve, 300));
  return false; // Replace with actual API call
};

// Validate space name uniqueness (mock implementation)
export const checkSpaceNameExists = async (name: string): Promise<boolean> => {
  // Simulating API call
  await new Promise((resolve) => setTimeout(resolve, 300));
  return false; // Replace with actual API call
};
