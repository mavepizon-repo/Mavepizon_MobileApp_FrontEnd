import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/freelancer/auth/freelancer_login_screen.dart';

// ── Team Lead Imports ───────────────────────────────────────────
import '../screens/team_lead/team_lead_main_screen.dart';
import '../screens/team_lead/dashboard/tl_dashboard_screen.dart';
import '../screens/team_lead/staff/tl_staff_list_screen.dart' as tl_staff;
import '../screens/team_lead/staff/tl_staff_detail_screen.dart'
    as tl_staff_detail;
import '../screens/team_lead/staff/tl_create_staff_screen.dart';
import '../screens/team_lead/staff/tl_edit_staff_screen.dart';
import '../screens/team_lead/tasks/tl_task_list_screen.dart';
import '../screens/team_lead/tasks/tl_task_detail_screen.dart';
import '../screens/team_lead/tasks/tl_assign_task_screen.dart';
import '../screens/team_lead/tasks/tl_edit_task_screen.dart';
import '../screens/team_lead/courses/tl_course_list_screen.dart';
import '../screens/team_lead/courses/tl_course_detail_screen.dart';
import '../screens/team_lead/courses/tl_create_course_screen.dart';
import '../screens/team_lead/courses/tl_edit_course_screen.dart';
import '../screens/team_lead/internships/tl_internship_list_screen.dart';
import '../screens/team_lead/internships/tl_internship_detail_screen.dart';
import '../screens/team_lead/internships/tl_create_internship_screen.dart';
import '../screens/team_lead/internships/tl_edit_internship_screen.dart';
import '../screens/team_lead/certificates/tl_certificate_screen.dart';
import '../screens/team_lead/students/tl_student_monitor_screen.dart';
import '../screens/team_lead/performance/tl_performance_screen.dart';
import '../screens/shared/monthly_report_screen.dart';
import '../screens/team_lead/profile/tl_profile_screen.dart';
import '../screens/team_lead/leave/tl_leave_management_screen.dart';
import '../screens/team_lead/leave/tl_apply_leave_screen.dart';
import '../screens/team_lead/leave/tl_leave_status_screen.dart';
import '../screens/team_lead/permission/tl_permission_management_screen.dart';
import '../screens/team_lead/permission/tl_apply_permission_screen.dart';
import '../screens/team_lead/permission/tl_permission_status_screen.dart';
import '../screens/team_lead/tasks/tl_task_review_screen.dart';
import '../screens/team_lead/attendance/tl_attendance_screen.dart';
import '../screens/team_lead/attendance/tl_attendance_history_screen.dart';

// ── Admin Imports ──────────────────────────────────────────────
import '../screens/admin/admin_main_screen.dart';
import '../screens/admin/dashboard/admin_dashboard_screen.dart';
import '../screens/admin/team_lead/admin_tl_list_screen.dart';
import '../screens/admin/team_lead/admin_tl_detail_screen.dart';
import '../screens/admin/team_lead/admin_tl_create_screen.dart';
import '../screens/admin/team_lead/admin_tl_edit_screen.dart';
import '../screens/admin/staff/admin_staff_list_screen.dart';
import '../screens/admin/staff/admin_staff_detail_screen.dart';
import '../screens/admin/staff/admin_staff_create_screen.dart';
import '../screens/admin/staff/admin_staff_edit_screen.dart';
import '../screens/admin/students/admin_student_list_screen.dart';
import '../screens/admin/students/admin_student_detail_screen.dart';
import '../screens/admin/courses/admin_course_list_screen.dart';
import '../screens/admin/courses/admin_course_create_screen.dart';
import '../screens/admin/courses/admin_course_detail_screen.dart';
import '../screens/admin/courses/admin_course_edit_screen.dart';
import '../screens/admin/internships/admin_internship_list_screen.dart';
import '../screens/admin/internships/admin_internship_create_screen.dart';
import '../screens/admin/internships/admin_internship_detail_screen.dart';

import '../screens/admin/internships/admin_internship_edit_screen.dart';
import '../screens/admin/payments/admin_payment_list_screen.dart';
import '../screens/admin/payments/admin_payment_detail_screen.dart';
import '../screens/admin/certificates/admin_certificate_list_screen.dart';
import '../screens/admin/certificates/admin_certificate_detail_screen.dart';
import '../screens/admin/leave/admin_leave_approval_screen.dart';
import '../screens/admin/permissions/admin_permission_approval_screen.dart';
import '../screens/admin/calendar/admin_calendar_screen.dart';
import '../screens/admin/holidays/admin_holidays_screen.dart';
import '../screens/admin/profile/admin_profile_screen.dart';
import '../screens/admin/college_staff/admin_college_staff_list_screen.dart';
import '../screens/admin/college_staff/admin_college_staff_detail_screen.dart';
import '../screens/admin/college_staff/admin_college_staff_create_screen.dart';
import '../screens/admin/tasks/admin_task_list_screen.dart';
import '../screens/admin/tasks/admin_assign_task_screen.dart';
import '../screens/admin/courses/admin_offered_course_list_screen.dart';
import '../screens/admin/courses/admin_offered_course_create_screen.dart';
import '../screens/admin/courses/admin_offered_course_edit_screen.dart';
import '../screens/admin/courses/admin_registration_list_screen.dart';
import '../screens/admin/telecalling/admin_telecalling_calls_screen.dart';

// ── College Staff Imports ──────────────────────────────────────
import '../screens/college_staff/college_staff_main_screen.dart';
import '../screens/college_staff/dashboard/college_staff_dashboard_screen.dart';
import '../screens/college_staff/profile/college_staff_profile_screen.dart';
import '../screens/college_staff/upload/college_staff_upload_screen.dart';
import '../screens/college_staff/files/college_staff_my_files_screen.dart';

// ── Freelancer Imports ─────────────────────────────────────────
import '../screens/freelancer/freelancer_main_screen.dart';
import '../screens/freelancer/dashboard/freelancer_dashboard_screen.dart';
import '../screens/freelancer/tasks/freelancer_my_tasks_screen.dart';
import '../screens/freelancer/tasks/freelancer_task_detail_screen.dart';
import '../screens/admin/freelancer/admin_freelancer_list_screen.dart';
import '../screens/admin/freelancer/admin_freelancer_detail_screen.dart';
import '../screens/admin/freelancer/admin_freelancer_create_screen.dart';
import '../screens/admin/freelancer/admin_freelancer_task_list_screen.dart';
import '../screens/admin/freelancer/admin_freelancer_task_detail_screen.dart';
import '../screens/admin/freelancer/admin_freelancer_task_create_screen.dart';

// ── Student Imports ─────────────────────────────────────────────
import '../screens/student/student_main_screen.dart';
import '../screens/student/dashboard/student_dashboard_screen.dart';
import '../screens/student/auth/student_register_screen.dart';
import '../screens/student/profile/student_profile_screen.dart';
import '../screens/student/profile/student_edit_profile_screen.dart';
import '../screens/student/courses/student_course_list_screen.dart';
import '../screens/student/courses/student_course_detail_screen.dart';
import '../screens/student/courses/student_course_register_screen.dart';
import '../screens/student/courses/student_my_courses_screen.dart';
import '../screens/student/internships/student_internship_list_screen.dart';
import '../screens/student/internships/student_internship_detail_screen.dart';
import '../screens/student/internships/student_internship_apply_screen.dart';
import '../screens/student/internships/student_my_internships_screen.dart';
import '../screens/student/payments/student_cash_payment_screen.dart';
import '../screens/student/payments/student_payment_history_screen.dart';
import '../screens/student/payments/student_online_payment_screen.dart';
import '../screens/student/certificates/student_certificate_screen.dart';
import '../screens/student/certificates/certificate_preview_screen.dart';
import '../widgets/certificate_template_view.dart';
import '../screens/student/notifications/student_notification_screen.dart';

// ── Staff Imports ───────────────────────────────────────────────
import '../screens/staff/staff_main_screen.dart';
import '../screens/staff/dashboard/staff_dashboard_screen.dart';
import '../screens/staff/designer/staff_certificate_create_screen.dart';
import '../screens/staff/profile/staff_profile_screen.dart';
import '../screens/staff/profile/staff_performance_screen.dart';
import '../screens/staff/attendance/staff_attendance_screen.dart';
import '../screens/staff/attendance/staff_attendance_history_screen.dart';
import '../screens/staff/leave/staff_apply_leave_screen.dart';
import '../screens/staff/leave/staff_leave_history_screen.dart';
import '../screens/staff/permissions/staff_apply_permission_screen.dart';
import '../screens/staff/permissions/staff_permission_history_screen.dart';
import '../screens/staff/tasks/staff_task_list_screen.dart';
import '../screens/staff/tasks/staff_task_detail_screen.dart';
import '../screens/staff/trainer/staff_trainer_batches_screen.dart';
import '../screens/staff/trainer/staff_trainer_batch_detail_screen.dart';
import '../screens/staff/trainer/staff_trainer_materials_screen.dart';
import '../screens/staff/trainer/staff_trainer_attendance_screen.dart';
import '../screens/staff/telecaller/staff_telecaller_enquiries_screen.dart';
import '../screens/staff/telecaller/staff_telecaller_enquiry_detail_screen.dart';
import '../screens/staff/telecaller/staff_telecaller_followups_screen.dart';

import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // ===================== AUTH =====================
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.forgotPassword:
        final role = args is Map ? args['role']?.toString() : null;
        return MaterialPageRoute(
            builder: (_) => ForgotPasswordScreen(role: role ?? ''));

      case AppRoutes.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());

      case AppRoutes.freelancerLogin:
        return MaterialPageRoute(
            builder: (_) => const FreelancerLoginScreen());

      // ===================== TEAM LEAD =====================
      case AppRoutes.teamLeadMain:
        return MaterialPageRoute(builder: (_) => const TeamLeadMainScreen());

      case AppRoutes.tlDashboard:
        return MaterialPageRoute(builder: (_) => const TlDashboardScreen());

      case AppRoutes.tlStaffList:
        return MaterialPageRoute(
            builder: (_) => const tl_staff.TlStaffListScreen());

      case AppRoutes.tlStaffDetail:
        final map = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) =>
                tl_staff_detail.TlStaffDetailScreen(staffId: map['staffId']));

      case AppRoutes.tlCreateStaff:
        return MaterialPageRoute(builder: (_) => const TlCreateStaffScreen());

      case AppRoutes.tlEditStaff:
        final map = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => TlEditStaffScreen(staffId: map['staffId']));

      case AppRoutes.tlTaskList:
        return MaterialPageRoute(builder: (_) => const TlTaskListScreen());

      case AppRoutes.tlTaskDetail:
        final map = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => TlTaskDetailScreen(taskId: map['taskId']));

      case AppRoutes.tlAssignTask:
        return MaterialPageRoute(builder: (_) => const TlAssignTaskScreen());

      case AppRoutes.tlEditTask:
        final map = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => TlEditTaskScreen(taskId: map['taskId']));

      case AppRoutes.tlCourseList:
        return MaterialPageRoute(builder: (_) => const TlCourseListScreen());

      case AppRoutes.tlCourseDetail:
        final map = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => TlCourseDetailScreen(courseId: map['courseId']));

      case AppRoutes.tlCreateCourse:
        return MaterialPageRoute(builder: (_) => const TlCreateCourseScreen());

      case AppRoutes.tlEditCourse:
        final map = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => TlEditCourseScreen(courseId: map['courseId']));

      case AppRoutes.tlInternshipList:
        return MaterialPageRoute(
            builder: (_) => const TlInternshipListScreen());

      case AppRoutes.tlInternshipDetail:
        final map = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) =>
                TlInternshipDetailScreen(internshipId: map['internshipId']));

      case AppRoutes.tlCreateInternship:
        return MaterialPageRoute(
            builder: (_) => const TlCreateInternshipScreen());

      case AppRoutes.tlEditInternship:
        final map = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) =>
                TlEditInternshipScreen(internshipId: map['internshipId']));

      case AppRoutes.tlCertificates:
        return MaterialPageRoute(builder: (_) => const TlCertificateScreen());

      case AppRoutes.tlStudentMonitor:
        return MaterialPageRoute(
            builder: (_) => const TlStudentMonitorScreen());

      case AppRoutes.tlPerformance:
        return MaterialPageRoute(builder: (_) => const TlPerformanceScreen());

      case AppRoutes.tlMonthlyReport:
        return MaterialPageRoute(
            builder: (_) => const MonthlyReportScreen(isAdmin: false));

      case AppRoutes.tlProfile:
        return MaterialPageRoute(builder: (_) => const TlProfileScreen());

      case AppRoutes.tlLeaveManagement:
        return MaterialPageRoute(
            builder: (_) => const TlLeaveManagementScreen());

      case AppRoutes.tlPermissionManagement:
        return MaterialPageRoute(
            builder: (_) => const TlPermissionManagementScreen());

      case AppRoutes.tlApplyLeave:
        return MaterialPageRoute(builder: (_) => const TlApplyLeaveScreen());

      case AppRoutes.tlApplyPermission:
        return MaterialPageRoute(
            builder: (_) => const TlApplyPermissionScreen());

      case AppRoutes.tlLeaveStatus:
        return MaterialPageRoute(
            builder: (_) => const TlLeaveStatusScreen());

      case AppRoutes.tlPermissionStatus:
        return MaterialPageRoute(
            builder: (_) => const TlPermissionStatusScreen());

      case AppRoutes.tlTaskReview:
        final trArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => TlTaskReviewScreen(
                taskId: trArgs['taskId']?.toString() ?? ''));

      case AppRoutes.tlAttendance:
        return MaterialPageRoute(
            builder: (_) => const TlAttendanceScreen());

      case AppRoutes.tlAttendanceHistory:
        return MaterialPageRoute(
            builder: (_) => const TlAttendanceHistoryScreen());

      // ===================== ADMIN =====================
      case AppRoutes.adminMain:
        return MaterialPageRoute(builder: (_) => const AdminMainScreen());

      case AppRoutes.adminMonthlyReport:
        return MaterialPageRoute(
            builder: (_) => const MonthlyReportScreen(isAdmin: true));

      case AppRoutes.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case AppRoutes.adminTlList:
        return MaterialPageRoute(builder: (_) => const AdminTlListScreen());

      case AppRoutes.adminStaffList:
        return MaterialPageRoute(builder: (_) => const AdminStaffListScreen());

      case AppRoutes.adminStudentList:
        return MaterialPageRoute(
            builder: (_) => const AdminStudentListScreen());

      case AppRoutes.adminProfile:
        return MaterialPageRoute(builder: (_) => const AdminProfileScreen());

      case AppRoutes.adminTlDetail:
        final tlArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) =>
                AdminTlDetailScreen(teamLeadId: tlArgs['id']?.toString() ?? ''));

      case AppRoutes.adminCreateTl:
        return MaterialPageRoute(builder: (_) => const AdminTlCreateScreen());

      case AppRoutes.adminEditTl:
        final editTlArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) =>
                AdminTlEditScreen(tlId: editTlArgs['id']?.toString() ?? ''));

      case AppRoutes.adminStaffDetail:
        final staffArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminStaffDetailScreen(
                staffId: staffArgs['id']?.toString() ?? ''));

      case AppRoutes.adminStudentDetail:
        final studentArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminStudentDetailScreen(
                studentId: studentArgs['id']?.toString() ?? ''));

      case AppRoutes.adminCourseList:
        return MaterialPageRoute(
            builder: (_) => const AdminCourseListScreen());

      case AppRoutes.adminInternshipList:
        return MaterialPageRoute(
            builder: (_) => const AdminInternshipListScreen());

      case AppRoutes.adminPaymentList:
        return MaterialPageRoute(
            builder: (_) => const AdminPaymentListScreen());

      case AppRoutes.adminCertificateList:
        return MaterialPageRoute(
            builder: (_) => const AdminCertificateListScreen());

      case AppRoutes.adminLeaveApproval:
        return MaterialPageRoute(
            builder: (_) => const AdminLeaveApprovalScreen());

      case AppRoutes.adminPermissionApproval:
        return MaterialPageRoute(
            builder: (_) => const AdminPermissionApprovalScreen());

      case AppRoutes.adminCalendar:
        return MaterialPageRoute(builder: (_) => const AdminCalendarScreen());

      case AppRoutes.adminHolidays:
        return MaterialPageRoute(builder: (_) => const AdminHolidaysScreen());

      case AppRoutes.adminCourseCreate:
        return MaterialPageRoute(
            builder: (_) => const AdminCourseCreateScreen());

      case AppRoutes.adminCourseDetail:
        final cdArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminCourseDetailScreen(
                courseId: cdArgs['courseId']?.toString() ?? ''));

      case AppRoutes.adminCourseEdit:
        final ceArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminCourseEditScreen(
                courseId: ceArgs['courseId']?.toString() ?? ''));

      case AppRoutes.adminInternshipCreate:
        return MaterialPageRoute(
            builder: (_) => const AdminInternshipCreateScreen());

      case AppRoutes.adminInternshipDetail:
        final idArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminInternshipDetailScreen(
                internshipId: idArgs['internshipId']?.toString() ?? ''));

      case AppRoutes.adminInternshipEdit:
        final ieArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminInternshipEditScreen(
                internshipId: ieArgs['internshipId']?.toString() ?? ''));

      case AppRoutes.adminStaffCreate:
        return MaterialPageRoute(
            builder: (_) => const AdminStaffCreateScreen());

      case AppRoutes.adminStaffEdit:
        final seArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminStaffEditScreen(
                staffId: seArgs['staffId']?.toString() ?? ''));

      case AppRoutes.adminPaymentDetail:
        final pdArgs = args is Map ? args : <String, dynamic>{};
        return MaterialPageRoute(
            builder: (_) => AdminPaymentDetailScreen(
                registrationId:
                    pdArgs['registrationId']?.toString() ?? ''));

      case AppRoutes.adminCertificateDetail:
        final certArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminCertificateDetailScreen(
                certificate: certArgs['certificate'] as dynamic));

      case AppRoutes.adminTelecallingCalls:
        return MaterialPageRoute(
            builder: (_) => const AdminTelecallingCallsScreen());

      // ===================== STAFF =====================
      case AppRoutes.staffMain:
        return MaterialPageRoute(builder: (_) => const StaffMainScreen());

      case AppRoutes.staffDashboard:
        return MaterialPageRoute(builder: (_) => const StaffDashboardScreen());

      case AppRoutes.staffCertificates:
        return MaterialPageRoute(
            builder: (_) => const StaffCertificateCreateScreen());

      case AppRoutes.staffProfile:
        return MaterialPageRoute(builder: (_) => const StaffProfileScreen());

      case AppRoutes.staffAttendance:
        return MaterialPageRoute(builder: (_) => const StaffAttendanceScreen());

      case AppRoutes.staffAttendanceHistory:
        return MaterialPageRoute(
            builder: (_) => const StaffAttendanceHistoryScreen());

      case AppRoutes.staffApplyLeave:
        return MaterialPageRoute(builder: (_) => const StaffApplyLeaveScreen());

      case AppRoutes.staffLeaveHistory:
        return MaterialPageRoute(
            builder: (_) => const StaffLeaveHistoryScreen());

      case AppRoutes.staffApplyPermission:
        return MaterialPageRoute(
            builder: (_) => const StaffApplyPermissionScreen());

      case AppRoutes.staffPermissionHistory:
        return MaterialPageRoute(
            builder: (_) => const StaffPermissionHistoryScreen());

      case AppRoutes.staffPerformance:
        return MaterialPageRoute(
            builder: (_) => const StaffPerformanceScreen());

      case AppRoutes.staffTaskList:
        return MaterialPageRoute(builder: (_) => const StaffTaskListScreen());

      case AppRoutes.staffTaskDetail:
        final taskArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => StaffTaskDetailScreen(
                taskId: taskArgs['taskId']?.toString() ?? ''));

      case AppRoutes.trainerBatches:
        return MaterialPageRoute(
            builder: (_) => const StaffTrainerBatchesScreen());

      case AppRoutes.trainerBatchDetail:
        final batchArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => StaffTrainerBatchDetailScreen(
                batchId: batchArgs['batchId']?.toString() ?? '',
                batchName: batchArgs['batchName']?.toString() ?? '',
                zoomLink: batchArgs['zoomLink']?.toString() ?? ''));

      case AppRoutes.trainerMaterials:
        return MaterialPageRoute(
            builder: (_) => const StaffTrainerMaterialsScreen());

      case AppRoutes.trainerAttendance:
        final taArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => StaffTrainerAttendanceScreen(
                batchId: taArgs['batchId']?.toString() ?? ''));

      case AppRoutes.telecallerEnquiries:
        return MaterialPageRoute(
            builder: (_) => const StaffTelecallerEnquiriesScreen());

      case AppRoutes.telecallerEnquiryDetail:
        final enqArgs = args as Map<String, dynamic>?;
        return MaterialPageRoute(
            builder: (_) => StaffTelecallerEnquiryDetailScreen(
                enquiryId: enqArgs?['enquiryId']?.toString(),
                mode: enqArgs?['mode']?.toString()));

      case AppRoutes.telecallerFollowups:
        return MaterialPageRoute(
            builder: (_) => const StaffTelecallerFollowupsScreen());

      // ===================== STUDENT =====================
      case AppRoutes.studentMain:
        return MaterialPageRoute(
            builder: (_) => const StudentMainScreen());

      case AppRoutes.studentDashboard:
        return MaterialPageRoute(
            builder: (_) => const StudentDashboardScreen());

      case AppRoutes.studentRegister:
        return MaterialPageRoute(
            builder: (_) => const StudentRegisterScreen());

      case AppRoutes.studentProfile:
        return MaterialPageRoute(
            builder: (_) => const StudentProfileScreen());

      case AppRoutes.studentEditProfile:
        return MaterialPageRoute(
            builder: (_) => const StudentEditProfileScreen());

      case AppRoutes.studentCourseList:
        return MaterialPageRoute(
            builder: (_) => const StudentCourseListScreen());

      case AppRoutes.studentCourseDetail:
        final cdArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => StudentCourseDetailScreen(
                courseId: cdArgs['courseId']?.toString() ?? ''));

      case AppRoutes.studentCourseRegister:
        final crArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => StudentCourseRegisterScreen(
                courseId: crArgs['courseId']?.toString() ?? '',
                courseName: crArgs['courseName']?.toString() ?? ''));

      case AppRoutes.studentMyCourses:
        return MaterialPageRoute(
            builder: (_) => const StudentMyCoursesScreen());

      case AppRoutes.studentInternshipList:
        return MaterialPageRoute(
            builder: (_) => const StudentInternshipListScreen());

      case AppRoutes.studentInternshipDetail:
        final idArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => StudentInternshipDetailScreen(
                internshipId:
                    idArgs['internshipId']?.toString() ?? ''));

      case AppRoutes.studentInternshipApply:
        final iaArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => StudentInternshipApplyScreen(
                internshipId: iaArgs['internshipId']?.toString() ?? '',
                title: iaArgs['internshipName']?.toString() ?? iaArgs['title']?.toString() ?? '',
                internshipCode: iaArgs['internshipCode']?.toString() ?? ''));

      case AppRoutes.studentMyInternships:
        return MaterialPageRoute(
            builder: (_) => const StudentMyInternshipsScreen());

      case AppRoutes.studentCashPayment:
        final cpArgs = args is Map ? args : <String, dynamic>{};
        return MaterialPageRoute(
            builder: (_) => StudentCashPaymentScreen(
                  registrationId: cpArgs['registrationId'] is int
                      ? cpArgs['registrationId']
                      : int.tryParse(
                          cpArgs['registrationId']?.toString() ?? ''),
                  internshipRegistrationId:
                      cpArgs['internshipRegistrationId'] is int
                          ? cpArgs['internshipRegistrationId']
                          : int.tryParse(cpArgs['internshipRegistrationId']
                                  ?.toString() ??
                              ''),
                  itemName: cpArgs['itemName']?.toString(),
                ));

      case AppRoutes.studentCashPaymentHistory:
        return MaterialPageRoute(
            builder: (_) => const StudentPaymentHistoryScreen());

      case AppRoutes.studentOnlinePayment:
        final opArgs = args is Map ? args : <String, dynamic>{};
        return MaterialPageRoute(
            builder: (_) => StudentOnlinePaymentScreen(
                  registrationId: opArgs['registrationId'] is int
                      ? opArgs['registrationId']
                      : int.tryParse(
                          opArgs['registrationId']?.toString() ?? ''),
                  itemName: opArgs['itemName']?.toString(),
                  amount: opArgs['amount'] is num
                      ? opArgs['amount'] as num
                      : null,
                ));

      case AppRoutes.studentCertificates:
        return MaterialPageRoute(
            builder: (_) => const StudentCertificateScreen());

      case AppRoutes.studentCertificatePreview:
        final prevArgs = args is Map ? args : <String, dynamic>{};
        final cert = prevArgs['certificate'] is Map
            ? Map<String, dynamic>.from(prevArgs['certificate'] as Map)
            : <String, dynamic>{};
        return MaterialPageRoute(
            builder: (_) => CertificatePreviewScreen(
                  data: CertificateData.fromCertificateJson(cert),
                ));

      case AppRoutes.studentNotifications:
        return MaterialPageRoute(
            builder: (_) => const StudentNotificationScreen());

      // ===================== ADMIN OFFERED COURSES =====================
      case AppRoutes.adminOfferedCourseList:
        return MaterialPageRoute(builder: (_) => const AdminOfferedCourseListScreen());

      case AppRoutes.adminOfferedCourseCreate:
        return MaterialPageRoute(builder: (_) => const AdminOfferedCourseCreateScreen());

      case AppRoutes.adminOfferedCourseEdit:
        final ocArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminOfferedCourseEditScreen(
                courseId: ocArgs['id']?.toString() ?? ''));

      // ===================== ADMIN REGISTRATIONS =====================
      case AppRoutes.adminRegistrationList:
        return MaterialPageRoute(builder: (_) => const AdminRegistrationListScreen());

      // ===================== ADMIN COLLEGE STAFF =====================
      case AppRoutes.adminCollegeStaffList:
        return MaterialPageRoute(
            builder: (_) => const AdminCollegeStaffListScreen());

      case AppRoutes.adminCollegeStaffDetail:
        final csArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminCollegeStaffDetailScreen(
                collegeStaffId: csArgs['id']?.toString() ?? ''));

      case AppRoutes.adminCollegeStaffCreate:
        return MaterialPageRoute(
            builder: (_) => const AdminCollegeStaffCreateScreen());

      // ===================== ADMIN TASKS =====================
      case AppRoutes.adminTaskList:
        final taskArgs = args as Map<String, dynamic>?;
        final initialStatus = taskArgs?['status']?.toString() ?? '';
        return MaterialPageRoute(
            builder: (_) =>
                AdminTaskListScreen(initialStatus: initialStatus));

      case AppRoutes.adminAssignTask:
        return MaterialPageRoute(builder: (_) => const AdminAssignTaskScreen());

      // ===================== COLLEGE STAFF =====================
      case AppRoutes.collegeStaffMain:
        return MaterialPageRoute(
            builder: (_) => const CollegeStaffMainScreen());

      case AppRoutes.collegeStaffDashboard:
        return MaterialPageRoute(
            builder: (_) => const CollegeStaffDashboardScreen());

      case AppRoutes.collegeStaffProfile:
        return MaterialPageRoute(
            builder: (_) => const CollegeStaffProfileScreen());

      case AppRoutes.collegeStaffUploadStudents:
        return MaterialPageRoute(
            builder: (_) => const CollegeStaffUploadScreen());

      case AppRoutes.collegeStaffMyFiles:
        return MaterialPageRoute(
            builder: (_) => const CollegeStaffMyFilesScreen());

      // ===================== FREELANCER =====================
      case AppRoutes.freelancerMain:
        return MaterialPageRoute(builder: (_) => const FreelancerMainScreen());

      case AppRoutes.freelancerDashboard:
        return MaterialPageRoute(
            builder: (_) => const FreelancerDashboardScreen());

      case AppRoutes.freelancerMyTasks:
        return MaterialPageRoute(
            builder: (_) => const FreelancerMyTasksScreen());

      case AppRoutes.freelancerTaskDetail:
        final flTaskArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => FreelancerTaskDetailScreen(
                taskId: flTaskArgs['id']?.toString() ?? ''));

      // ===================== ADMIN FREELANCER =====================
      case AppRoutes.adminFreelancerList:
        return MaterialPageRoute(
            builder: (_) => const AdminFreelancerListScreen());

      case AppRoutes.adminFreelancerDetail:
        final flDetailArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminFreelancerDetailScreen(
                freelancerId: flDetailArgs['id']?.toString() ?? ''));

      case AppRoutes.adminFreelancerCreate:
        return MaterialPageRoute(
            builder: (_) => const AdminFreelancerCreateScreen());

      case AppRoutes.adminFreelancerEdit:
        final flEditArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminFreelancerCreateScreen(
                freelancerId: flEditArgs['id']?.toString()));

      case AppRoutes.adminFreelancerTaskList:
        return MaterialPageRoute(
            builder: (_) => const AdminFreelancerTaskListScreen());

      case AppRoutes.adminFreelancerTaskDetail:
        final fltDetailArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminFreelancerTaskDetailScreen(
                taskId: fltDetailArgs['id']?.toString() ?? ''));

      case AppRoutes.adminFreelancerTaskCreate:
        return MaterialPageRoute(
            builder: (_) => const AdminFreelancerTaskCreateScreen());

      case AppRoutes.adminFreelancerTaskEdit:
        final fltEditArgs = args as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => AdminFreelancerTaskCreateScreen(
                taskId: fltEditArgs['id']?.toString()));

      // ===================== DEFAULT =====================
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}


