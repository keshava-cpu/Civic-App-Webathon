enum IssueStatus {
  pending,
  assigned,
  inProgress,
  resolved,
  verified,
}

enum IssueCategory {
  pothole,
  streetlight,
  garbage,
  graffiti,
  flooding,
  brokenSidewalk,
  noisePollution,
  illegalDumping,
  parkDamage,
  other,
}

extension IssueCategoryExt on IssueCategory {
  String get label {
    switch (this) {
      case IssueCategory.pothole:
        return 'Pothole';
      case IssueCategory.streetlight:
        return 'Street Light';
      case IssueCategory.garbage:
        return 'Garbage';
      case IssueCategory.graffiti:
        return 'Graffiti';
      case IssueCategory.flooding:
        return 'Flooding';
      case IssueCategory.brokenSidewalk:
        return 'Broken Sidewalk';
      case IssueCategory.noisePollution:
        return 'Noise Pollution';
      case IssueCategory.illegalDumping:
        return 'Illegal Dumping';
      case IssueCategory.parkDamage:
        return 'Park Damage';
      case IssueCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case IssueCategory.pothole:
        return '🕳️';
      case IssueCategory.streetlight:
        return '💡';
      case IssueCategory.garbage:
        return '🗑️';
      case IssueCategory.graffiti:
        return '🎨';
      case IssueCategory.flooding:
        return '🌊';
      case IssueCategory.brokenSidewalk:
        return '🚶';
      case IssueCategory.noisePollution:
        return '🔊';
      case IssueCategory.illegalDumping:
        return '♻️';
      case IssueCategory.parkDamage:
        return '🌳';
      case IssueCategory.other:
        return '❓';
    }
  }
}

extension IssueStatusExt on IssueStatus {
  String get label {
    switch (this) {
      case IssueStatus.pending:
        return 'Pending';
      case IssueStatus.assigned:
        return 'Assigned';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.resolved:
        return 'Resolved';
      case IssueStatus.verified:
        return 'Verified';
    }
  }

  String get value {
    switch (this) {
      case IssueStatus.pending:
        return 'pending';
      case IssueStatus.assigned:
        return 'assigned';
      case IssueStatus.inProgress:
        return 'inProgress';
      case IssueStatus.resolved:
        return 'resolved';
      case IssueStatus.verified:
        return 'verified';
    }
  }
}

IssueStatus issueStatusFromString(String s) {
  switch (s) {
    case 'assigned':
      return IssueStatus.assigned;
    case 'inProgress':
      return IssueStatus.inProgress;
    case 'resolved':
      return IssueStatus.resolved;
    case 'verified':
      return IssueStatus.verified;
    default:
      return IssueStatus.pending;
  }
}

IssueCategory? issueCategoryFromString(String s) {
  return null;
}

IssueCategory categoryFromString(String s) {
  return IssueCategory.values.firstWhere(
    (e) => e.name == s,
    orElse: () => IssueCategory.other,
  );
}

// Points
const int kPointsReport = 10;
const int kPointsUpvote = 2;
const int kPointsVerify = 15;
const int kPointsTask = 5;
const int kPointsVerificationReversal = 5;

// Duplicate detection
const double kDuplicateRadiusMeters = 100.0;

// Verification threshold (weighted score needed to auto-verify)
const double kVerificationThreshold = 0.6;
const int kMinVerifications = 3;

// Badge thresholds
const int kBadgeBronzeCredits = 50;
const int kBadgeSilverCredits = 200;
const int kBadgeGoldCredits = 500;

// Nearby notification radius
const double kNearbyNotificationRadiusMeters = 500.0;
