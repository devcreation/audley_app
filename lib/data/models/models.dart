// ─── App Config (unauthenticated — branding for login/register) ─────
class AppConfig {
  final String appName;
  final String logoUrl;
  final EventInfo event;
  final Map<String, String> ui;

  AppConfig({this.appName = '', this.logoUrl = '', required this.event, this.ui = const {}});

  factory AppConfig.fromJson(Map<String, dynamic> j) {
    final uiRaw = j['ui'] as Map? ?? {};
    final uiMap = <String, String>{};
    uiRaw.forEach((k, v) => uiMap[k.toString()] = v?.toString() ?? '');
    return AppConfig(
      appName: j['app_name']?.toString() ?? '',
      logoUrl: j['logo_url']?.toString() ?? '',
      event: EventInfo.fromJson(Map<String, dynamic>.from(j['event'] ?? {})),
      ui: uiMap,
    );
  }

  String uiString(String key, [String fallback = '']) => ui[key] ?? fallback;
}

// ─── Event Info ─────────────────────────────────────────────
class EventInfo {
  final String name, badge, subtitle, dates, targetDate, heroImage;
  EventInfo({this.name = '', this.badge = '', this.subtitle = '', this.dates = '', this.targetDate = '', this.heroImage = ''});
  factory EventInfo.fromJson(Map<String, dynamic> j) => EventInfo(
    name: j['name'] ?? '', badge: j['badge'] ?? '', subtitle: j['subtitle'] ?? '',
    dates: j['dates'] ?? '', targetDate: j['targetDate'] ?? '', heroImage: j['hero_image'] ?? '');
}

// ─── Programme ──────────────────────────────────────────────
class ProgrammeDay {
  final String day, date, dateFull, location, image;
  final List<ProgrammeItem> items;
  ProgrammeDay({this.day='', this.date='', this.dateFull='', this.location='', this.image='', this.items=const[]});
  factory ProgrammeDay.fromJson(Map<String, dynamic> j) => ProgrammeDay(
    day: j['day']??'', date: j['date']??'', dateFull: j['dateFull']??'', location: j['location']??'', image: j['image']??'',
    items: (j['items'] as List?)?.map((i) => ProgrammeItem.fromJson(i)).toList() ?? []);
}

class ProgrammeItem {
  final String time, title, group, type, sub;
  ProgrammeItem({this.time='', this.title='', this.group='', this.type='normal', this.sub=''});
  factory ProgrammeItem.fromJson(Map<String, dynamic> j) => ProgrammeItem(
    time: j['time']??'', title: j['title']??'', group: j['group']??'', type: j['type']??'normal', sub: j['sub']??'');
}

// ─── Hotel ──────────────────────────────────────────────────
class Hotel {
  final String name, desc, url, image;
  Hotel({this.name='', this.desc='', this.url='', this.image=''});
  factory Hotel.fromJson(Map<String, dynamic> j) => Hotel(name: j['name']??'', desc: j['desc']??'', url: j['url']??'', image: j['image']??'');
}

// ─── Fleet ──────────────────────────────────────────────────
class FleetVehicle {
  final String name, desc, video, image;
  FleetVehicle({this.name='', this.desc='', this.video='', this.image=''});
  factory FleetVehicle.fromJson(Map<String, dynamic> j) => FleetVehicle(name: j['name']??'', desc: j['desc']??'', video: j['video']??'', image: j['image']??'');
}

// ─── Contacts ───────────────────────────────────────────────
class Contacts {
  final String office, emergency, email;
  final List<ContactPerson> people;
  final List<HotelContact> hotelContacts;
  Contacts({this.office='', this.emergency='', this.email='', this.people=const[], this.hotelContacts=const[]});
  factory Contacts.fromJson(Map<String, dynamic> j) => Contacts(
    office: j['office']??'', emergency: j['emergency']??'', email: j['email']??'',
    people: (j['people'] as List?)?.map((i) => ContactPerson.fromJson(i)).toList() ?? [],
    hotelContacts: (j['hotelContacts'] as List?)?.map((i) => HotelContact.fromJson(i)).toList() ?? []);
}
class ContactPerson {
  final String role, name, phone;
  ContactPerson({this.role='', this.name='', this.phone=''});
  factory ContactPerson.fromJson(Map<String, dynamic> j) => ContactPerson(role: j['role']??'', name: j['name']??'', phone: j['phone']??'');
}
class HotelContact {
  final String name, city, phone, email;
  HotelContact({this.name='', this.city='', this.phone='', this.email=''});
  factory HotelContact.fromJson(Map<String, dynamic> j) => HotelContact(name: j['name']??'', city: j['city']??'', phone: j['phone']??'', email: j['email']??'');
}

// ─── FAQ ────────────────────────────────────────────────────
class FaqItem {
  final String q, a, cat;
  FaqItem({this.q='', this.a='', this.cat=''});
  factory FaqItem.fromJson(Map<String, dynamic> j) => FaqItem(q: j['q']??'', a: j['a']??'', cat: j['cat']??'');
}

// ─── Update ─────────────────────────────────────────────────
class TripUpdate {
  final bool pinned;
  final String tag, date, title, body;
  TripUpdate({this.pinned=false, this.tag='', this.date='', this.title='', this.body=''});
  factory TripUpdate.fromJson(Map<String, dynamic> j) => TripUpdate(
    pinned: j['pinned'] ?? false, tag: j['tag']??'', date: j['date']??'', title: j['title']??'', body: j['body']??'');
}


// ─── Sponsor ────────────────────────────────────────────────
class Sponsor {
  final String name, image;
  Sponsor({this.name='', this.image=''});
  factory Sponsor.fromJson(Map<String, dynamic> j) => Sponsor(name: j['name']??'', image: j['image']??'');
}

// ─── Full SiteData ──────────────────────────────────────────
class SiteData {
  final EventInfo event;
  final List<ProgrammeDay> programme;
  final List<Hotel> hotels;
  final List<FleetVehicle> fleet;
  final Contacts contacts;
  final List<FaqItem> faqs;
  final List<TripUpdate> updates;
  final List<Sponsor> sponsors;
  final String? travelGuidelinesUrl;

  SiteData({required this.event, required this.programme, required this.hotels,
    required this.fleet, required this.contacts, required this.faqs,
    required this.updates, required this.sponsors, this.travelGuidelinesUrl});

  factory SiteData.fromJson(Map<String, dynamic> j) => SiteData(
    event: EventInfo.fromJson(j['event'] ?? {}),
    programme: (j['programme']?['days'] as List?)?.map((d) => ProgrammeDay.fromJson(d)).toList() ?? [],
    hotels: (j['hotels'] as List?)?.map((h) => Hotel.fromJson(h)).toList() ?? [],
    fleet: (j['fleet'] as List?)?.map((f) => FleetVehicle.fromJson(f)).toList() ?? [],
    contacts: Contacts.fromJson(j['contacts'] ?? {}),
    faqs: (j['faqs'] as List?)?.map((f) => FaqItem.fromJson(f)).toList() ?? [],
    updates: (j['updates'] as List?)?.map((u) => TripUpdate.fromJson(u)).toList() ?? [],
    sponsors: (j['sponsors'] as List?)?.map((s) => Sponsor.fromJson(s)).toList() ?? [],
    travelGuidelinesUrl: j['travel_guidelines_url'],
  );
}
