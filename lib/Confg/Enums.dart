enum UserState{
  New,
  underReview,
  approved,
  unApproved,
  onConflict,
  banned
}
enum AuthStatus { unknown, authenticated, unauthenticated }
enum Roles {user,manager,admin ,developer}
enum OwnerTypes {owner,rental}
enum Storage {googleDrive,superbaseStorage,both}
enum MaintenanceCategory {plumbing,electricity,gardening , structural ,peast_control ,elevator , other}
enum SecurityCategory {disturbance ,sabotage, theft , other}
enum CareServiceCategory {building_cleaning,trash_pickup , other}
enum MaintenanceReportType{ maintenance,security, careService}

enum ReportAUserFilter{
  All,
  New,
  inReview,
  Resolved
}

enum ReportAUserType{
  spam,
  harassment,
  selling,
  inappropriateContent
}