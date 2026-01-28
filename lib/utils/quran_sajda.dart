// Minimal Sajdah metadata (index, position, page, type)

class SajdaInfo {
  final int index; // 1..15
  final String position;
  final int page; // 1-604
  final String sajdahType;

  const SajdaInfo(this.index, this.position, this.page, this.sajdahType);
}

List<SajdaInfo> quranSajdahData = [
  SajdaInfo(1, "7:206", 176, "اختيارية"),
  SajdaInfo(2, "13:15", 251, "اختيارية"),
  SajdaInfo(3, "16:50", 272, "اختيارية"),
  SajdaInfo(4, "17:109", 293, "اختيارية"),
  SajdaInfo(5, "19:58", 309, "اختيارية"),
  SajdaInfo(6, "22:18", 334, "اختيارية"),
  SajdaInfo(7, "22:77", 341, "اختيارية"),
  SajdaInfo(8, "25:60", 365, "اختيارية"),
  SajdaInfo(9, "27:26", 379, "اختيارية"),
  SajdaInfo(10, "32:15", 416, "إجبارية"),
  SajdaInfo(11, "38:24", 454, "اختيارية"),
  SajdaInfo(12, "41:38", 480, "إجبارية"),
  SajdaInfo(13, "53:62", 528, "إجبارية"),
  SajdaInfo(14, "84:21", 589, "اختيارية"),
  SajdaInfo(15, "96:19", 597, "إجبارية"),
];
