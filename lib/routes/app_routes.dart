class AppRoutes {
  AppRoutes._();

  // ===================== AUTH =====================
  static const String splash = '/splash';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';
  static const String freelancerLogin = '/freelancer-login';

  // ===================== TEAM LEAD =====================
  static const String teamLeadMain = '/team-lead-main';
  static const String tlDashboard = '/team-lead/dashboard';
  static const String tlStaffList = '/team-lead/staff';
  static const String tlStaffDetail = '/team-lead/staff-detail';
  static const String tlCreateStaff = '/team-lead/create-staff';
  static const String tlEditStaff = '/team-lead/edit-staff';
  static const String tlTaskList = '/team-lead/tasks';
  static const String tlTaskDetail = '/team-lead/task-detail';
  static const String tlAssignTask = '/team-lead/assign-task';
  static const String tlEditTask = '/team-lead/edit-task';
  static const String tlCourseList = '/team-lead/courses';
  static const String tlCourseDetail = '/team-lead/course-detail';
  static const String tlCreateCourse = '/team-lead/create-course';
  static const String tlEditCourse = '/team-lead/edit-course';
  static const String tlInternshipList = '/team-lead/internships';
  static const String tlInternshipDetail = '/team-lead/internship-detail';
  static const String tlCreateInternship = '/team-lead/create-internship';
  static const String tlEditInternship = '/team-lead/edit-internship';
  static const String tlCertificates = '/team-lead/certificates';
  static const String tlStudentMonitor = '/team-lead/student-monitor';
  static const String tlPerformance = '/team-lead/performance';
  static const String tlMonthlyReport = '/team-lead/monthly-report';
  static const String tlProfile = '/team-lead/profile';
  static const String tlLeaveManagement = '/team-lead/leave-management';
  static const String tlPermissionManagement = '/team-lead/permission-management';
  static const String tlApplyLeave = '/team-lead/apply-leave';
  static const String tlApplyPermission = '/team-lead/apply-permission';
  static const String tlLeaveStatus = '/team-lead/leave-status';
  static const String tlPermissionStatus = '/team-lead/permission-status';
  static const String tlTaskReview = '/team-lead/task-review';
  static const String tlAttendance = '/team-lead/attendance';
  static const String tlAttendanceHistory = '/team-lead/attendance-history';
  static const String tlNotifications = '/team-lead/notifications';

  // ===================== ADMIN =====================
  static const String adminMain = '/admin-main';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminTlList = '/admin/team-leads';
  static const String adminTlDetail = '/admin/team-lead-detail';
  static const String adminCreateTl = '/admin/create-team-lead';
  static const String adminEditTl = '/admin/edit-team-lead';
  static const String adminStaffList = '/admin/staff';
  static const String adminStaffDetail = '/admin/staff-detail';
  static const String adminStaffCreate = '/admin/create-staff';
  static const String adminStaffEdit = '/admin/edit-staff';
  static const String adminStudentList = '/admin/students';
  static const String adminStudentDetail = '/admin/student-detail';
  static const String adminCourseList = '/admin/courses';
  static const String adminCourseCreate = '/admin/create-course';
  static const String adminCourseDetail = '/admin/course-detail';
  static const String adminCourseEdit = '/admin/edit-course';
  static const String adminInternshipList = '/admin/internships';
  static const String adminInternshipCreate = '/admin/create-internship';
  static const String adminInternshipDetail = '/admin/internship-detail';
  static const String adminInternshipEdit = '/admin/edit-internship';
  static const String adminPaymentList = '/admin/payments';
  static const String adminPaymentDetail = '/admin/payment-detail';
  static const String adminCertificateList = '/admin/certificates';
  static const String adminCertificateDetail = '/admin/certificate-detail';
  static const String adminLeaveApproval = '/admin/leave-approval';
  static const String adminPermissionApproval = '/admin/permission-approval';
  static const String adminCalendar = '/admin/calendar';
  static const String adminHolidays = '/admin/holidays';
  static const String adminProfile = '/admin/profile';
  static const String adminTelecallingCalls = '/admin/telecalling-calls';
  static const String adminMonthlyReport = '/admin/monthly-report';

  // ===================== STAFF (OfficeStaff) =====================
  static const String staffMain = '/staff-main';
  static const String staffDashboard = '/staff/dashboard';
  static const String staffProfile = '/staff/profile';
  static const String staffAttendance = '/staff/attendance';
  static const String staffAttendanceHistory = '/staff/attendance-history';
  static const String staffApplyLeave = '/staff/apply-leave';
  static const String staffLeaveHistory = '/staff/leave-history';
  static const String staffApplyPermission = '/staff/apply-permission';
  static const String staffPermissionHistory = '/staff/permission-history';
  static const String staffPerformance = '/staff/performance';
  static const String staffTaskList = '/staff/tasks';
  static const String staffTaskDetail = '/staff/task-detail';
  static const String trainerBatches = '/staff/trainer-batches';
  static const String trainerBatchDetail = '/staff/trainer-batch-detail';
  static const String trainerMaterials = '/staff/trainer-materials';
  static const String trainerFeeConfirmation = '/staff/trainer-fee-confirmation';
  static const String trainerAttendance = '/staff/trainer-attendance';
  static const String trainerZoomLink = '/staff/trainer-zoom-link';
  static const String telecallerEnquiries = '/staff/telecaller-enquiries';
  static const String telecallerEnquiryDetail = '/staff/telecaller-enquiry-detail';
  static const String telecallerFollowups = '/staff/telecaller-followups';
  static const String staffCertificates = '/staff/certificates';

  // ===================== STUDENT =====================
  static const String studentMain = '/student-main';
  static const String studentDashboard = '/student/dashboard';
  static const String studentProfile = '/student/profile';
  static const String studentEditProfile = '/student/edit-profile';
  static const String studentRegister = '/student/register';
  static const String studentCourseList = '/student/courses';
  static const String studentCourseDetail = '/student/course-detail';
  static const String studentCourseRegister = '/student/course-register';
  static const String studentMyCourses = '/student/my-courses';
  static const String studentInternshipList = '/student/internships';
  static const String studentInternshipDetail = '/student/internship-detail';
  static const String studentInternshipApply = '/student/internship-apply';
  static const String studentMyInternships = '/student/my-internships';
  static const String studentCashPayment = '/student/cash-payment';
  static const String studentCashPaymentHistory = '/student/cash-payment-history';
  static const String studentOnlinePayment = '/student/online-payment';
  static const String studentCertificates = '/student/certificates';
  static const String studentCertificatePreview = '/student/certificate-preview';
  static const String studentNotifications = '/student/notifications';

  // ===================== ADMIN OFFERED COURSES =====================
  static const String adminOfferedCourseList = '/admin/offered-courses';
  static const String adminOfferedCourseCreate = '/admin/create-offered-course';
  static const String adminOfferedCourseEdit = '/admin/edit-offered-course';

  // ===================== ADMIN REGISTRATIONS =====================
  static const String adminRegistrationList = '/admin/registrations';

  // ===================== ADMIN COLLEGE STAFF =====================
  static const String adminCollegeStaffList = '/admin/college-staff';
  static const String adminCollegeStaffDetail = '/admin/college-staff-detail';
  static const String adminCollegeStaffCreate = '/admin/create-college-staff';

  // ===================== ADMIN TASKS =====================
  static const String adminTaskList = '/admin/tasks';
  static const String adminAssignTask = '/admin/assign-task';

  // ===================== COLLEGE STAFF =====================
  static const String collegeStaffMain = '/college-staff-main';
  static const String collegeStaffDashboard = '/college-staff/dashboard';
  static const String collegeStaffProfile = '/college-staff/profile';
  static const String collegeStaffUploadStudents = '/college-staff/upload-students';
  static const String collegeStaffMyFiles = '/college-staff/my-files';

  // ===================== FREELANCER =====================
  static const String freelancerMain = '/freelancer-main';
  static const String freelancerDashboard = '/freelancer/dashboard';
  static const String freelancerMyTasks = '/freelancer/my-tasks';
  static const String freelancerTaskDetail = '/freelancer/task-detail';

  // ===================== ADMIN FREELANCER =====================
  static const String adminFreelancerList = '/admin/freelancers';
  static const String adminFreelancerDetail = '/admin/freelancer-detail';
  static const String adminFreelancerCreate = '/admin/create-freelancer';
  static const String adminFreelancerEdit = '/admin/edit-freelancer';
  static const String adminFreelancerTaskList = '/admin/freelancer-tasks';
  static const String adminFreelancerTaskDetail = '/admin/freelancer-task-detail';
  static const String adminFreelancerTaskCreate = '/admin/create-freelancer-task';
  static const String adminFreelancerTaskEdit = '/admin/edit-freelancer-task';
}
