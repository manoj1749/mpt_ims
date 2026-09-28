const bool useMagnetPowerTech = true; // Set to false for Aimant Industries

/// Company code prefix used for auto-generated codes.
const String companyCodePrefix = useMagnetPowerTech ? 'MPT' : 'AI';

/// Prefix used for auto-generated Purchase Order numbers.
/// MagnetPowerTech -> 'M', Aimant Industries -> 'AI'.
const String poNumberPrefix = useMagnetPowerTech ? 'M' : 'AI';

/// Root Firestore document for company-specific data.
/// MagnetPowerTech -> 'Magnet', Aimant Industries -> 'Aimant'.
const String firestoreRootCollection = useMagnetPowerTech ? 'Magnet' : 'Aimant';

/// Root Firestore document for shared data (common to all companies).
const String firestoreSharedRoot = 'Shared';

/// Collections that are shared across all companies.
/// These are stored under the 'Shared' root document.
const Set<String> sharedCollections = {
  'suppliers',
  'materials',
  'categories',
  'subCategories',
};
