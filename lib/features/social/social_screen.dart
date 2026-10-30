import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../game/state/game_state.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key, this.firebaseReady = true});

  final bool firebaseReady;

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final _searchController = TextEditingController();
  final Set<String> _busyPlayers = <String>{};
  bool _searching = false;
  String? _message;
  bool _messageIsError = false;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String get _myName => context.read<GameState>().playerName.trim();

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _feedback(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsError = error;
    });
  }

  String _firebaseError(Object error, {String fallback = 'تعذرت العملية.'}) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'قواعد Firestore رفضت العملية. انشر نسخة firestore.rules المحدثة في Firebase Console.';
        case 'unavailable':
        case 'network-request-failed':
          return 'تعذر الاتصال بقاعدة البيانات. تحقق من الإنترنت وحاول مرة ثانية.';
        case 'unauthenticated':
          return 'انتهت جلسة الدخول. سجّل الدخول من جديد.';
        case 'already-exists':
          return 'يوجد طلب صداقة أو علاقة مسجلة مسبقاً.';
        default:
          return '$fallback (${error.code})';
      }
    }
    return fallback;
  }

  Future<void> _sendFriendRequest() async {
    final uid = _uid;
    final search = _searchController.text.trim();
    final senderName = _myName.isEmpty ? 'مزارع' : _myName;
    if (uid == null) {
      _feedback('سجّل الدخول أولاً لإرسال طلب صداقة.', error: true);
      return;
    }
    if (search.isEmpty) {
      _feedback('اكتب اسم اللاعب أو UID الخاص به.', error: true);
      return;
    }

    setState(() {
      _searching = true;
      _message = null;
    });
    try {
      DocumentSnapshot<Map<String, dynamic>> profile = await _db.collection('publicProfiles').doc(search).get();
      var targetUid = search;

      if (!profile.exists) {
        final matches = await _db.collection('publicProfiles').where('name', isEqualTo: search).limit(2).get();
        if (matches.docs.isEmpty) {
          _feedback('ما لكيت لاعب بهذا الاسم أو المعرّف. لازم اللاعب يفتح اللعبة مرة واحدة ويتصل بالسحابة حتى يظهر. ', error: true);
          return;
        }
        if (matches.docs.length > 1) {
          _feedback('أكو أكثر من لاعب بهذا الاسم؛ استخدم UID حتى تحدد الشخص الصحيح.', error: true);
          return;
        }
        profile = matches.docs.first;
        targetUid = profile.id;
      }

      if (targetUid == uid) {
        _feedback('ما تكدر ترسل طلب صداقة لنفسك.', error: true);
        return;
      }

      final rawTargetName = (profile.data()?['name'] as String?)?.trim();
      final targetName = rawTargetName == null || rawTargetName.isEmpty
          ? 'مزارع'
          : rawTargetName.length > 24
              ? rawTargetName.substring(0, 24)
              : rawTargetName;
      final incomingRef = _db.collection('users').doc(targetUid).collection('friendRequests').doc(uid);
      final outgoingRef = _db.collection('users').doc(uid).collection('sentRequests').doc(targetUid);
      final incomingToMeRef = _db.collection('users').doc(uid).collection('friendRequests').doc(targetUid);
      final myFriendRef = _db.collection('users').doc(uid).collection('friends').doc(targetUid);

      await _db.runTransaction<void>((transaction) async {
        final outgoing = await transaction.get(outgoingRef);
        final incoming = await transaction.get(incomingRef);
        final incomingToMe = await transaction.get(incomingToMeRef);
        final myFriend = await transaction.get(myFriendRef);

        if (myFriend.exists) throw StateError('هذا اللاعب موجود بقائمة أصدقائك بالفعل.');
        if (incomingToMe.exists) throw StateError('هذا اللاعب مرسل لك طلب صداقة؛ افتح تبويب الطلبات الواردة واقبله.');
        if (outgoing.exists || incoming.exists) throw StateError('طلب الصداقة مرسل سابقاً وما زال بانتظار الرد.');

        transaction.set(incomingRef, {
          'fromUid': uid,
          'fromName': senderName,
          'toUid': targetUid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
        transaction.set(outgoingRef, {
          'fromUid': uid,
          'fromName': senderName,
          'toUid': targetUid,
          'toName': targetName,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      });

      _searchController.clear();
      _feedback('انرسل طلب الصداقة إلى $targetName.');
    } on StateError catch (error) {
      _feedback(error.message.toString(), error: true);
    } catch (error) {
      _feedback(_firebaseError(error, fallback: 'تعذر إرسال طلب الصداقة.'), error: true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _acceptRequest(String fromUid) async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _busyPlayers.add(fromUid));
    try {
      final requestRef = _db.collection('users').doc(uid).collection('friendRequests').doc(fromUid);
      final myFriendRef = _db.collection('users').doc(uid).collection('friends').doc(fromUid);
      final theirFriendRef = _db.collection('users').doc(fromUid).collection('friends').doc(uid);
      final sentRef = _db.collection('users').doc(fromUid).collection('sentRequests').doc(uid);

      await _db.runTransaction<void>((transaction) async {
        final request = await transaction.get(requestRef);
        final myFriend = await transaction.get(myFriendRef);
        final theirFriend = await transaction.get(theirFriendRef);
        if (!request.exists) throw StateError('طلب الصداقة لم يعد موجوداً. حدّث القائمة وحاول من جديد.');

        if (!myFriend.exists) {
          transaction.set(myFriendRef, {'uid': fromUid, 'addedAt': FieldValue.serverTimestamp()});
        }
        if (!theirFriend.exists) {
          transaction.set(theirFriendRef, {'uid': uid, 'addedAt': FieldValue.serverTimestamp()});
        }
        transaction.delete(requestRef);
        transaction.delete(sentRef);
      });
      _feedback('تم قبول طلب الصداقة وإضافة اللاعب إلى قائمة الطرفين.');
    } on StateError catch (error) {
      _feedback(error.message.toString(), error: true);
    } catch (error) {
      _feedback(_firebaseError(error, fallback: 'تعذر قبول طلب الصداقة.'), error: true);
    } finally {
      if (mounted) setState(() => _busyPlayers.remove(fromUid));
    }
  }

  Future<void> _declineRequest(String fromUid) async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _busyPlayers.add(fromUid));
    try {
      final batch = _db.batch();
      batch.delete(_db.collection('users').doc(uid).collection('friendRequests').doc(fromUid));
      batch.delete(_db.collection('users').doc(fromUid).collection('sentRequests').doc(uid));
      await batch.commit();
      _feedback('تم رفض طلب الصداقة.');
    } catch (error) {
      _feedback(_firebaseError(error, fallback: 'تعذر رفض طلب الصداقة.'), error: true);
    } finally {
      if (mounted) setState(() => _busyPlayers.remove(fromUid));
    }
  }

  Future<void> _cancelRequest(String toUid) async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _busyPlayers.add(toUid));
    try {
      final batch = _db.batch();
      batch.delete(_db.collection('users').doc(uid).collection('sentRequests').doc(toUid));
      batch.delete(_db.collection('users').doc(toUid).collection('friendRequests').doc(uid));
      await batch.commit();
      _feedback('تم إلغاء طلب الصداقة.');
    } catch (error) {
      _feedback(_firebaseError(error, fallback: 'تعذر إلغاء طلب الصداقة.'), error: true);
    } finally {
      if (mounted) setState(() => _busyPlayers.remove(toUid));
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _busyPlayers.add(friendUid));
    try {
      final batch = _db.batch();
      batch.delete(_db.collection('users').doc(uid).collection('friends').doc(friendUid));
      batch.delete(_db.collection('users').doc(friendUid).collection('friends').doc(uid));
      await batch.commit();
      _feedback('تم حذف الصداقة من قائمة الطرفين.');
    } catch (error) {
      _feedback(_firebaseError(error, fallback: 'تعذر حذف الصديق.'), error: true);
    } finally {
      if (mounted) setState(() => _busyPlayers.remove(friendUid));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseReady) {
      return const _NoticePanel(
        icon: Icons.cloud_off_rounded,
        title: 'Firebase غير متاح',
        message: 'الميزات الاجتماعية تتطلب اتصالاً ناجحاً بقاعدة البيانات. أعد تشغيل الاتصال ثم حاول مرة ثانية.',
      );
    }
    final uid = _uid;
    if (uid == null) {
      return const _NoticePanel(
        icon: Icons.lock_outline_rounded,
        title: 'سجّل الدخول أولاً',
        message: 'لوحة الشرف والأصدقاء متاحة للاعبين المسجلين بحساب Firebase.',
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.wood.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.dark,
            indicator: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(14),
            ),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            tabs: const [
              Tab(text: '🏆 الشرف'),
              Tab(text: '👥 أصدقائي'),
              Tab(text: '📥 واردة'),
              Tab(text: '📤 مرسلة'),
            ],
          ),
        ),
        if (_message != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: (_messageIsError ? AppColors.red : AppColors.green).withValues(alpha: .11),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (_messageIsError ? AppColors.red : AppColors.green).withValues(alpha: .35)),
            ),
            child: Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _messageIsError ? AppColors.red : AppColors.dark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [_leaderboard(), _friends(), _incomingRequests(), _outgoingRequests()],
          ),
        ),
      ],
    );
  }

  Widget _leaderboard() {
    final stream = _db
        .collection('publicProfiles')
        .orderBy('updated', descending: true)
        .limit(100)
        .snapshots();
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(13, 8, 13, 8),
          child: Text('مجتمع اللاعبين — القائمة حسب آخر نشاط، وليست ترتيباً اقتصادياً',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _NoticePanel(
                  icon: Icons.cloud_off_rounded,
                  title: 'تعذر تحميل لوحة الشرف',
                  message: _firebaseError(snapshot.error!, fallback: 'تحقق من نشر قواعد Firestore واتصال الإنترنت.'),
                  onRetry: () => setState(() {}),
                );
              }
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs.toList();
              if (docs.isEmpty) {
                return const _NoticePanel(
                  icon: Icons.emoji_events_outlined,
                  title: 'لوحة الشرف فارغة حالياً',
                  message: 'تظهر أسماء اللاعبين بعد تسجيل الدخول ونجاح مزامنة ملفهم الشخصي مع Firestore.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final me = doc.id == _uid;
                  final name = (data['name'] as String?)?.trim();
                  final medal = switch (index) { 0 => '🥇', 1 => '🥈', 2 => '🥉', _ => '${index + 1}' };
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: index < 3 ? AppColors.gold.withValues(alpha: .2) : AppColors.cream,
                        child: Text(medal, style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      title: Text(
                        '${name?.isNotEmpty == true ? name : 'مزارع'}${me ? ' (أنت)' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: const Text('مزارع في المجتمع'),
                    
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _friends() {
    final uid = _uid!;
    final friendStream = _db.collection('users').doc(uid).collection('friends').snapshots();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _sendFriendRequest(),
                  decoration: const InputDecoration(
                    labelText: 'اسم اللاعب أو UID',
                    hintText: 'ابحث عن مزارع',
                    prefixIcon: Icon(Icons.person_search_rounded),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _searching ? null : _sendFriendRequest,
                  child: _searching
                      ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.person_add_alt_1_rounded),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 2, 12, 7),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('تقدر تبحث بالاسم أو UID، والإضافة تصير بعد قبول الطلب.', style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: friendStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _NoticePanel(
                  icon: Icons.cloud_off_rounded,
                  title: 'تعذر تحميل الأصدقاء',
                  message: _firebaseError(snapshot.error!, fallback: 'تحقق من قواعد Firestore واتصال الإنترنت.'),
                  onRetry: () => setState(() {}),
                );
              }
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final friends = snapshot.data!.docs;
              if (friends.isEmpty) {
                return const _NoticePanel(
                  icon: Icons.people_outline_rounded,
                  title: 'قائمة الأصدقاء فارغة',
                  message: 'ابحث عن لاعب وأرسل له طلب صداقة. سيظهر هنا بعد أن يقبل الطلب.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                itemCount: friends.length,
                separatorBuilder: (_, __) => const SizedBox(height: 5),
                itemBuilder: (context, index) => _friendTile(friends[index].id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _friendTile(String friendUid) {
    final profileStream = _db.collection('publicProfiles').doc(friendUid).snapshots();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['name'] as String?)?.trim();
        final busy = _busyPlayers.contains(friendUid);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE1F3D6), child: Text('🌾')),
            title: Text(name?.isNotEmpty == true ? name! : 'مزارع', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: const Text('صديق في مزرعتك'),
            trailing: IconButton(
              tooltip: 'إزالة الصديق',
              onPressed: busy ? null : () => _removeFriend(friendUid),
              icon: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.person_remove_alt_1_rounded, color: AppColors.red),
            ),
            onTap: () => _showFarmVisit(friendUid, data),
          ),
        );
      },
    );
  }

  Widget _incomingRequests() {
    final uid = _uid!;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(uid).collection('friendRequests').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _NoticePanel(
            icon: Icons.cloud_off_rounded,
            title: 'تعذر تحميل الطلبات الواردة',
            message: _firebaseError(snapshot.error!, fallback: 'تحقق من قواعد Firestore واتصال الإنترنت.'),
            onRetry: () => setState(() {}),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!.docs;
        if (requests.isEmpty) {
          return const _NoticePanel(
            icon: Icons.mark_email_read_outlined,
            title: 'ما عندك طلبات واردة',
            message: 'طلبات الصداقة اللي يرسلها اللاعبون إلك راح تظهر هنا.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final doc = requests[index];
            final fromUid = doc.id;
            final data = doc.data();
            final name = (data['fromName'] as String?)?.trim();
            final busy = _busyPlayers.contains(fromUid);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person_add_alt_1_rounded)),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name?.isNotEmpty == true ? name! : 'مزارع', style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text('يريد إضافتك صديقاً', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'قبول',
                      onPressed: busy ? null : () => _acceptRequest(fromUid),
                      icon: busy
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_circle_rounded, color: AppColors.green),
                    ),
                    IconButton(
                      tooltip: 'رفض',
                      onPressed: busy ? null : () => _declineRequest(fromUid),
                      icon: const Icon(Icons.cancel_rounded, color: AppColors.red),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _outgoingRequests() {
    final uid = _uid!;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(uid).collection('sentRequests').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _NoticePanel(
            icon: Icons.cloud_off_rounded,
            title: 'تعذر تحميل الطلبات المرسلة',
            message: _firebaseError(snapshot.error!, fallback: 'تحقق من قواعد Firestore واتصال الإنترنت.'),
            onRetry: () => setState(() {}),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!.docs;
        if (requests.isEmpty) {
          return const _NoticePanel(
            icon: Icons.outbox_outlined,
            title: 'ما عندك طلبات معلّقة',
            message: 'الطلبات اللي ترسلها للآخرين راح تبقى هنا إلى أن يوافقوا أو تلغيها.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final doc = requests[index];
            final toUid = doc.id;
            final data = doc.data();
            final name = (data['toName'] as String?)?.trim();
            final busy = _busyPlayers.contains(toUid);
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.hourglass_top_rounded)),
                title: Text(name?.isNotEmpty == true ? name! : 'مزارع', style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('بانتظار قبول طلب الصداقة'),
                trailing: TextButton(
                  onPressed: busy ? null : () => _cancelRequest(toUid),
                  child: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('إلغاء'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showFarmVisit(String friendUid, Map<String, dynamic>? profile) async {
    if (!mounted) return;
    List<Map<String, dynamic>> plots = <Map<String, dynamic>>[];
    try {
      final snapshot = await _db.collection('farmSnapshots').doc(friendUid).get();
      final rawPlots = snapshot.data()?['plots'];
      if (rawPlots is List) {
        plots = rawPlots.whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList();
      }
    } catch (error) {
      _feedback(_firebaseError(error, fallback: 'تعذر تحميل مزرعة الصديق.'), error: true);
      return;
    }
    if (!mounted) return;
    final name = profile?['name'] as String? ?? 'مزرعة صديق';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('زيارة $name'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('مزرعة الصديق — عرض فقط', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (plots.isEmpty)
                const Text('لم يشارك هذا اللاعب لقطة مزرعته بعد. افتح اللعبة لديه واتصل بالإنترنت لتحديثها.')
              else
                Flexible(
                  child: SizedBox(
                    height: 260,
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: plots.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemBuilder: (context, index) {
                        final plot = plots[index];
                        final cropId = plot['cropId'] as String?;
                        final plantedAt = DateTime.tryParse(plot['plantedAt'] as String? ?? '');
                        final seconds = (plot['growSeconds'] as num?)?.toInt() ?? 0;
                        final ready = cropId != null && plantedAt != null &&
                            !context.read<GameState>().serverNow.isBefore(plantedAt.add(Duration(seconds: seconds)));
                        return Container(
                          decoration: BoxDecoration(
                            color: cropId == null ? Colors.brown.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cropId == null ? '🟫' : (ready ? '🌾' : '🌱'), style: const TextStyle(fontSize: 26)),
                              Text(cropId == null ? 'فارغة' : (ready ? 'جاهز' : 'ينمو'),
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text('لا يمكنك الحصاد أو الشراء أو تغيير بيانات مزرعة صديقك.'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
      ),
    );
  }
}

class _NoticePanel extends StatelessWidget {
  const _NoticePanel({required this.icon, required this.title, required this.message, this.onRetry});

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .86),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColors.green.withValues(alpha: .12), shape: BoxShape.circle),
                  child: Icon(icon, size: 32, color: AppColors.green),
                ),
                const SizedBox(height: 12),
                Text(title, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.dark)),
                const SizedBox(height: 7),
                Text(message, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted)),
                if (onRetry != null) ...[
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
