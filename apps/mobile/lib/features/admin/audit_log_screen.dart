import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/audit_provider.dart';
import '../../core/models/audit_log.dart';
import '../../shared/utils/date_helpers.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  List<AuditLog> _logs = [];
  bool _loading = true;
  int _page = 1;
  int _total = 0;
  String? _actionFilter;

  final _actionTypes = [
    null,
    'EMPLOYEE_CREATED',
    'EMPLOYEE_UPDATED',
    'MANUAL_ATTENDANCE',
    'SALARY_GENERATED',
    'SALARY_REGENERATED',
    'LEAVE_APPROVED',
    'LEAVE_REJECTED',
    'HOLIDAY_CREATED',
    'HOLIDAY_DELETED',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() { _loading = true; _page = 1; });
    }
    try {
      final result = await ref.read(auditRepoProvider).getAuditLogs(
        action: _actionFilter,
        page: _page,
        limit: 30,
      );
      setState(() {
        if (loadMore) {
          _logs.addAll(result['logs'] as List<AuditLog>);
        } else {
          _logs = result['logs'] as List<AuditLog>;
        }
        _total = result['total'] as int;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: Column(
        children: [
          // Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String?>(
              value: _actionFilter,
              hint: const Text('Filter by action'),
              items: _actionTypes.map((a) => DropdownMenuItem(
                value: a,
                child: Text(a ?? 'All Actions'),
              )).toList(),
              onChanged: (v) {
                _actionFilter = v;
                _loadLogs();
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('No audit logs found'))
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification &&
                              notification.metrics.extentAfter < 100 &&
                              _logs.length < _total) {
                            _page++;
                            _loadLogs(loadMore: true);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          log.action,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        DateHelpers.formatDateTime(log.createdAt),
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${log.entityType} (${log.entityId.substring(0, 8)}...)',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                  if (log.details != null && log.details!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        log.details.toString(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
