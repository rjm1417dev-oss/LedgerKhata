/// The shop's timezone is Asia/Karachi: UTC+5 all year (Pakistan has no
/// daylight saving since 2009). Every stored instant is a UTC timestamp; this
/// converts it to the shop's wall-clock time so that day grouping and
/// displayed times don't depend on the phone's own timezone setting.
///
/// The result is a plain (non-UTC) DateTime holding Karachi wall-clock
/// fields, so `.year/.month/.day/.hour` and DateFormat give shop time
/// directly. Use it only for display and day grouping, never to send a time
/// back to the database.
///
/// If a per-tenant timezone setting is ever added, this is the one place to
/// change.
const Duration kShopUtcOffset = Duration(hours: 5);

DateTime shopTime(DateTime instant) {
  final shifted = instant.toUtc().add(kShopUtcOffset);
  return DateTime(
    shifted.year,
    shifted.month,
    shifted.day,
    shifted.hour,
    shifted.minute,
    shifted.second,
    shifted.millisecond,
    shifted.microsecond,
  );
}
