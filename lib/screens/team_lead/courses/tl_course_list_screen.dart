import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/internship_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_widget.dart';
import '../../../widgets/pagination_bar.dart';
import '../../../widgets/status_badge.dart';

class TlCourseListScreen extends ConsumerStatefulWidget {
  const TlCourseListScreen({super.key});
  @override
  ConsumerState<TlCourseListScreen> createState() => _TlCourseListScreenState();
}

class _TlCourseListScreenState extends ConsumerState<TlCourseListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseProvider.notifier).fetch();
      ref.read(internshipProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = ref.watch(courseProvider);
    final ip = ref.watch(internshipProvider);

    final courses = cp.list.where((c) {
      // /api/course/get-all returns both categories; this is the Courses tab.
      if (c.category.toUpperCase() != 'COURSE') return false;
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty &&
          !c.courseName.toLowerCase().contains(q) &&
          !c.courseCode.toLowerCase().contains(q) &&
          !c.batchId.toLowerCase().contains(q))
        return false;
      if (_statusFilter.isNotEmpty &&
          !c.status.toUpperCase().contains(_statusFilter))
        return false;
      return true;
    }).toList();

    final internships = ip.list.where((i) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty &&
          !i.internshipName.toLowerCase().contains(q) &&
          !i.internshipCode.toLowerCase().contains(q) &&
          !i.trainerName.toLowerCase().contains(q))
        return false;
      if (_statusFilter.isNotEmpty &&
          !i.status.toUpperCase().contains(_statusFilter))
        return false;
      return true;
    }).toList();

    return Scaffold(
      
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 16, 20, 0),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Courses & Internships',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              GestureDetector(
                  onTap: () {
                    if (_tab.index == 0) {
                      Navigator.pushNamed(context, AppRoutes.tlCreateCourse)
                          .then((_) => cp.fetch());
                    } else {
                      Navigator.pushNamed(context, AppRoutes.tlCreateInternship)
                          .then((_) => ip.fetch());
                    }
                  },
                  child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 20))),
            ]),
            const SizedBox(height: 16),
            TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: [
                Tab(text: 'Courses (${courses.length})'),
                Tab(text: 'Internships (${internships.length})'),
              ],
            ),
            const SizedBox(height: 8),
          ]),
        ),
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, code, trainer...',
              prefixIcon:
                  Icon(Icons.search_rounded, color: AppColors.textHi(context)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      })
                  : null,
            ),
          ),
        ),
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FChip(context, 'All', '', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Active', 'ACTIVE', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Inactive', 'INACTIVE', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
            ]),
          ),
        ),
        Expanded(
          child: ResponsiveCentered(
            child: TabBarView(controller: _tab, children: [
            // Courses Tab
            Column(children: [
              Expanded(
                child: cp.isLoading
                    ? const LoadingWidget(message: 'Loading courses...')
                    : courses.isEmpty
                        ? EmptyWidget(
                            message: cp.list.isEmpty
                                ? 'No courses yet'
                                : 'No courses match filter',
                            icon: Icons.menu_book_outlined,
                            actionLabel: '+ Create Course',
                            onAction: () => Navigator.pushNamed(
                                context, AppRoutes.tlCreateCourse))
                        : RefreshIndicator(
                            onRefresh: () => cp.refresh(),
                            color: AppColors.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                              itemCount: courses.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final c = courses[i];
                                return _CourseCard(
                                  title: c.courseName,
                                  code: c.courseCode,
                                  status: c.status,
                                  duration: c.duration,
                                  trainer: c.batchId,
                                  fees: c.totalFees,
                                  availableOnline: c.availableSeatsOnline,
                                  totalOnline: c.totalSeatsOnline,
                                  availableOffline: c.availableSeatsOffline,
                                  totalOffline: c.totalSeatsOffline,
                                  color: AppColors.card1,
                                  onTap: () => Navigator.pushNamed(
                                          context, AppRoutes.tlCourseDetail,
                                          arguments: {'courseId': c.id})
                                      .then((_) => cp.refresh()),
                                );
                              },
                            ),
                          ),
              ),
              PaginationBar(
                data: cp.pagination,
                isLoading: cp.isLoading,
                onPageChanged: (page) =>
                    ref.read(courseProvider.notifier).fetch(page: page),
              ),
            ]),

            // Internships Tab
            ip.isLoading
                ? const LoadingWidget(message: 'Loading internships...')
                : internships.isEmpty
                    ? EmptyWidget(
                        message: ip.list.isEmpty
                            ? 'No internships yet'
                            : 'No internships match filter',
                        icon: Icons.work_outline,
                        actionLabel: '+ Create Internship',
                        onAction: () => Navigator.pushNamed(
                            context, AppRoutes.tlCreateInternship))
                    : RefreshIndicator(
                        onRefresh: () => ip.fetch(),
                        color: AppColors.accent,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          itemCount: internships.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final intern = internships[i];
                            return _CourseCard(
                              title: intern.internshipName,
                              code: intern.internshipCode,
                              status: intern.status,
                              duration: intern.duration,
                              trainer: intern.trainerName,
                              fees: intern.fees,
                              availableOnline: intern.availableSeatsOnline,
                              totalOnline: intern.totalSeatsOnline,
                              availableOffline: intern.availableSeatsOffline,
                              totalOffline: intern.totalSeatsOffline,
                              color: AppColors.card2,
                              onTap: () => Navigator.pushNamed(
                                      context, AppRoutes.tlInternshipDetail,
                                      arguments: {'internshipId': intern.id})
                                  .then((_) => ip.fetch()),
                            );
                          },
                        ),
                      ),
          ]),
            ),
        ),
      ]),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String title, code, status, duration, trainer;
  final double fees;
  final int availableOnline, totalOnline, availableOffline, totalOffline;
  final Color color;
  final VoidCallback onTap;

  const _CourseCard({
    required this.title,
    required this.code,
    required this.status,
    required this.duration,
    required this.trainer,
    required this.fees,
    required this.availableOnline,
    required this.totalOnline,
    required this.availableOffline,
    required this.totalOffline,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: [
          Container(
              height: 4,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context)))),
                const SizedBox(width: 8),
                StatusBadge(status: status),
              ]),
              const SizedBox(height: 4),
              Text(code,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textHi(context))),
              const SizedBox(height: 6),
              Row(children: [
                _SeatChip('Online', availableOnline, totalOnline, color),
                const SizedBox(width: 8),
                _SeatChip('Offline', availableOffline, totalOffline, color),
              ]),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('?${fees.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_rounded,
                      size: 13, color: color.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(trainer,
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSec(context),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Icon(Icons.timer_rounded,
                      size: 13, color: color.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(duration,
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSec(context),
                          fontWeight: FontWeight.w500)),
                ]),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

Widget _SeatChip(String label, int available, int total, Color color) {
  final fill = total > 0 ? available / total : 1.0;
  final chipColor =
      fill > 0.5 ? AppColors.success : (fill > 0.2 ? AppColors.warning : AppColors.error);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: chipColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text('$label: $available/$total',
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: chipColor)),
  );
}

Widget _FChip(BuildContext context, String label, String value, String current, void Function(String) onSelected) {
  final selected = current == value;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: () => onSelected(selected ? '' : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSec(context))),
      ),
    ),
  );
}
