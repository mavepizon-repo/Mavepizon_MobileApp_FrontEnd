import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/course_utils.dart';
import '../../../providers/student_course_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/pagination_bar.dart';

class StudentCourseListScreen extends ConsumerStatefulWidget {
  const StudentCourseListScreen({super.key, this.initialOffered = false});
  final bool initialOffered;
  @override
  ConsumerState<StudentCourseListScreen> createState() =>
      _StudentCourseListScreenState();
}

class _StudentCourseListScreenState
    extends ConsumerState<StudentCourseListScreen> {
  late bool _offeredOnly;

  @override
  void initState() {
    super.initState();
    _offeredOnly = widget.initialOffered;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentCourseProvider.notifier).fetchAvailableCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp = ref.watch(studentCourseProvider);
    final courses = _offeredOnly
        ? cp.courses.where(isOfferedCourse).toList()
        : cp.courses;

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_offeredOnly ? 'Offered Courses' : 'Courses',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.list_alt_rounded,
                color: AppColors.textSec(context)),
            onPressed: () => Navigator.pushNamed(
                context, AppRoutes.studentMyCourses),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(children: [
            _filterChip(context, 'All Courses', !_offeredOnly, () {
              setState(() => _offeredOnly = false);
            }),
            const SizedBox(width: 8),
            _filterChip(context, 'Offered Only', _offeredOnly, () {
              setState(() => _offeredOnly = true);
            }),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(studentCourseProvider.notifier)
                .refreshAvailableCourses(),
            child: cp.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2))
                : courses.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.menu_book_rounded,
                                  size: 60,
                                  color: AppColors
                                      .textHi(context)
                                      .withOpacity(0.4)),
                              const SizedBox(height: 16),
                              Text(
                                  _offeredOnly
                                      ? 'No offered courses right now'
                                      : 'No courses available',
                                  style: TextStyle(
                                      color:
                                          AppColors.textHi(context))),
                            ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: courses.length,
                        itemBuilder: (ctx, i) {
                          final c = courses[i];
                          return GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.studentCourseDetail,
                                arguments: {
                                  'courseId': c['id']?.toString() ?? ''
                                }),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2))
                                  ]),
                              child: Row(children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.card1.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                      child: Icon(Icons.menu_book_rounded,
                                          color: AppColors.card1, size: 24)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            c['courseName']?.toString() ??
                                                'Course',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors
                                                    .textPri(context))),
                                        const SizedBox(height: 4),
                                        Text(
                                            '${c['duration']?.toString() ?? ''}  •  ₹${c['registrationFees']?.toString() ?? '0'}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors
                                                    .textSec(context))),
                                        const SizedBox(height: 4),
                                        Text(
                                            'Seats: ${c['availableSeatsOnline'] ?? 0} online / ${c['availableSeatsOffline'] ?? 0} offline',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.accent)),
                                        if ((c['availableSeatsTirunelveli'] ?? 0) > 0 || (c['availableSeatsTisaiyanvilai'] ?? 0) > 0)
                                          Text(
                                              'TV: ${c['availableSeatsTirunelveli'] ?? 0} / TY: ${c['availableSeatsTisaiyanvilai'] ?? 0}',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.card2)),
                                      ]),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textHi(context)),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ),
        PaginationBar(
          data: cp.pagination,
          isLoading: cp.isLoading,
          onPageChanged: (page) => ref
              .read(studentCourseProvider.notifier)
              .fetchAvailableCourses(page: page),
        ),
      ]),
    );
  }

  Widget _filterChip(BuildContext context, String label, bool selected,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.textSec(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSec(context)),
        ),
      ),
    );
  }
}
