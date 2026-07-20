/// All data models matching the website's SITE_DATA JSON structure.
/// These are deserialized from the /api/content.php response.

class SiteData {
  final EventInfo event;
  final Programme programme;
  final List<Hotel> hotels;
  final List<FleetVehicle> fleet;
  final Contacts contacts;
  final List<Faq> faqs;
  final List<TripUpdate> updates;
  final String? travelGuidelinesUrl;

  SiteData({
    required this.event,
    required this.programme,
    required this.hotels,
    required this.fleet,
    required this.contacts,
    required this.faqs,
    required this.updates,
    this.travelGuidelinesUrl,
  });

  factory SiteData.fromJson(Map<String, dynamic> json) {
    return SiteData(
      event: EventInfo.fromJson(json['event'] ?? {}),
      programme: Programme.fromJson(json['programme'] ?? {}),
      hotels:
          (json['hotels'] as List? ?? []).map((h) => Hotel.fromJson(h)).toList(),
      fleet: (json['fleet'] as List? ?? [])
          .map((f) => FleetVehicle.fromJson(f))
          .toList(),
      contacts: Contacts.fromJson(json['contacts'] ?? {}),
      faqs: (json['faqs'] as List? ?? []).map((f) => Faq.fromJson(f)).toList(),
      updates: (json['updates'] as List? ?? [])
          .map((u) => TripUpdate.fromJson(u))
          .toList(),
      travelGuidelinesUrl: json['travel_guidelines_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'event': event.toJson(),
        'programme': programme.toJson(),
        'hotels': hotels.map((h) => h.toJson()).toList(),
        'fleet': fleet.map((f) => f.toJson()).toList(),
        'contacts': contacts.toJson(),
        'faqs': faqs.map((f) => f.toJson()).toList(),
        'updates': updates.map((u) => u.toJson()).toList(),
        'travel_guidelines_url': travelGuidelinesUrl,
      };
}

class EventInfo {
  final String name;
  final String badge;
  final String subtitle;
  final String dates;
  final String targetDate;

  EventInfo({
    required this.name,
    required this.badge,
    required this.subtitle,
    required this.dates,
    required this.targetDate,
  });

  factory EventInfo.fromJson(Map<String, dynamic> json) => EventInfo(
        name: json['name'] ?? '',
        badge: json['badge'] ?? '',
        subtitle: json['subtitle'] ?? '',
        dates: json['dates'] ?? '',
        targetDate: json['targetDate'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'badge': badge,
        'subtitle': subtitle,
        'dates': dates,
        'targetDate': targetDate,
      };
}

class Programme {
  final List<ProgrammeDay> days;

  Programme({required this.days});

  factory Programme.fromJson(Map<String, dynamic> json) => Programme(
        days: (json['days'] as List? ?? [])
            .map((d) => ProgrammeDay.fromJson(d))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'days': days.map((d) => d.toJson()).toList(),
      };
}

class ProgrammeDay {
  final String day;
  final String date;
  final String dateFull;
  final String location;
  final String? image;
  final List<ScheduleItem> items;

  ProgrammeDay({
    required this.day,
    required this.date,
    required this.dateFull,
    required this.location,
    this.image,
    required this.items,
  });

  factory ProgrammeDay.fromJson(Map<String, dynamic> json) => ProgrammeDay(
        day: json['day'] ?? '',
        date: json['date'] ?? '',
        dateFull: json['dateFull'] ?? '',
        location: json['location'] ?? '',
        image: json['image'],
        items: (json['items'] as List? ?? [])
            .map((i) => ScheduleItem.fromJson(i))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'date': date,
        'dateFull': dateFull,
        'location': location,
        'image': image,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class ScheduleItem {
  final String time;
  final String title;
  final String? sub;
  final String? group;
  final String type; // 'normal', 'highlight', 'gala'

  ScheduleItem({
    required this.time,
    required this.title,
    this.sub,
    this.group,
    required this.type,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
        time: json['time'] ?? '',
        title: json['title'] ?? '',
        sub: json['sub'],
        group: json['group'],
        type: json['type'] ?? 'normal',
      );

  Map<String, dynamic> toJson() => {
        'time': time,
        'title': title,
        'sub': sub,
        'group': group,
        'type': type,
      };
}

class Hotel {
  final String name;
  final String desc;
  final String? url;
  final String? image;

  Hotel({
    required this.name,
    required this.desc,
    this.url,
    this.image,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) => Hotel(
        name: json['name'] ?? '',
        desc: json['desc'] ?? '',
        url: json['url'],
        image: json['image'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'desc': desc,
        'url': url,
        'image': image,
      };
}

class FleetVehicle {
  final String name;
  final String desc;
  final String? video;
  final String? image;

  FleetVehicle({
    required this.name,
    required this.desc,
    this.video,
    this.image,
  });

  factory FleetVehicle.fromJson(Map<String, dynamic> json) => FleetVehicle(
        name: json['name'] ?? '',
        desc: json['desc'] ?? '',
        video: json['video'],
        image: json['image'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'desc': desc,
        'video': video,
        'image': image,
      };
}

class Contacts {
  final String office;
  final String emergency;
  final String email;
  final List<ContactPerson> people;
  final List<HotelContact> hotelContacts;

  Contacts({
    required this.office,
    required this.emergency,
    required this.email,
    required this.people,
    required this.hotelContacts,
  });

  factory Contacts.fromJson(Map<String, dynamic> json) => Contacts(
        office: json['office'] ?? '',
        emergency: json['emergency'] ?? '',
        email: json['email'] ?? '',
        people: (json['people'] as List? ?? [])
            .map((p) => ContactPerson.fromJson(p))
            .toList(),
        hotelContacts: (json['hotelContacts'] as List? ?? [])
            .map((h) => HotelContact.fromJson(h))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'office': office,
        'emergency': emergency,
        'email': email,
        'people': people.map((p) => p.toJson()).toList(),
        'hotelContacts': hotelContacts.map((h) => h.toJson()).toList(),
      };
}

class ContactPerson {
  final String role;
  final String name;
  final String phone;

  ContactPerson({
    required this.role,
    required this.name,
    required this.phone,
  });

  factory ContactPerson.fromJson(Map<String, dynamic> json) => ContactPerson(
        role: json['role'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'name': name,
        'phone': phone,
      };
}

class HotelContact {
  final String name;
  final String city;
  final String phone;
  final String email;

  HotelContact({
    required this.name,
    required this.city,
    required this.phone,
    required this.email,
  });

  factory HotelContact.fromJson(Map<String, dynamic> json) => HotelContact(
        name: json['name'] ?? '',
        city: json['city'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'city': city,
        'phone': phone,
        'email': email,
      };
}

class Faq {
  final String q;
  final String a;
  final String cat;

  Faq({required this.q, required this.a, required this.cat});

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
        q: json['q'] ?? '',
        a: json['a'] ?? '',
        cat: json['cat'] ?? '',
      );

  Map<String, dynamic> toJson() => {'q': q, 'a': a, 'cat': cat};
}

class TripUpdate {
  final bool pinned;
  final String tag;
  final String date;
  final String title;
  final String body;

  TripUpdate({
    required this.pinned,
    required this.tag,
    required this.date,
    required this.title,
    required this.body,
  });

  factory TripUpdate.fromJson(Map<String, dynamic> json) => TripUpdate(
        pinned: json['pinned'] == true,
        tag: json['tag'] ?? 'Info',
        date: json['date'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'pinned': pinned,
        'tag': tag,
        'date': date,
        'title': title,
        'body': body,
      };
}

// ─── Auth / Form models ─────────────────────────────────────

class AppUser {
  final int id;
  final String name;
  final String? email;

  AppUser({required this.id, required this.name, this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] ?? 0,
        name: json['name'] ?? json['full_name'] ?? '',
        email: json['email'],
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

class Participant {
  final String name;
  final String mobile;
  final String email;

  Participant({
    required this.name,
    required this.mobile,
    required this.email,
  });

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        name: json['name'] ?? '',
        mobile: json['mobile'] ?? '',
        email: json['email'] ?? '',
      );
}
