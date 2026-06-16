import '../models/household.dart';
import '../models/user_membership.dart';
import '../services/remote/household_remote_service.dart';
import '../services/remote/membership_remote_service.dart';

class HouseholdMembership {
  const HouseholdMembership({
    required this.household,
    required this.membership,
  });

  final Household household;
  final UserMembership membership;
}

class HouseholdRepository {
  HouseholdRepository({
    HouseholdRemoteService? householdRemoteService,
    MembershipRemoteService? membershipRemoteService,
  })  : _householdRemoteService =
            householdRemoteService ?? HouseholdRemoteService(),
        _membershipRemoteService =
            membershipRemoteService ?? MembershipRemoteService();

  final HouseholdRemoteService _householdRemoteService;
  final MembershipRemoteService _membershipRemoteService;

  Future<HouseholdMembership> getOrCreatePrivateHouseholdForUser({
    required String userId,
  }) async {
    var membership =
        await _membershipRemoteService.getMembershipForUser(userId);

    if (membership == null) {
      final householdId = await _householdRemoteService.createPrivateHousehold(
        createdBy: userId,
      );

      await _membershipRemoteService.createMembershipForUser(
        userId: userId,
        householdId: householdId,
        role: 'owner',
      );

      membership =
          await _membershipRemoteService.getMembershipForUser(userId);
    }

    if (membership == null) {
      throw StateError('Membership konnte nicht geladen werden.');
    }

    if (!membership.aktiv) {
      throw StateError('Membership ist nicht aktiv.');
    }

    if (membership.householdId.isEmpty) {
      throw StateError('Membership hat keine Household-ID.');
    }

    final household = await _householdRemoteService.getHouseholdById(
      membership.householdId,
    );

    if (household == null) {
      throw StateError('Haushalt konnte nicht geladen werden.');
    }

    return HouseholdMembership(
      household: household,
      membership: membership,
    );
  }
}
