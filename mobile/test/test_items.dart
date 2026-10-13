import 'package:dept_rental/item_model.dart';
import 'package:dept_rental/item_store.dart';

ItemStore testItemStore() => ItemStore(
  initialItems: const [
    RentalItem(
      id: 1,
      name: '4090본체',
      category: '전자기기',
      location: '2210호에 배치된 본체',
      total: 18,
      initialAvailable: 18,
      kind: ProductKind.desktop,
    ),
    RentalItem(
      id: 2,
      name: '4090본체',
      category: '전자기기',
      location: '2211호에 배치된 본체',
      total: 27,
      initialAvailable: 27,
      kind: ProductKind.desktop,
    ),
    RentalItem(
      id: 3,
      name: '모니터',
      category: '전자기기',
      location: '2210호에 배치된 모니터',
      total: 30,
      initialAvailable: 30,
      kind: ProductKind.monitor,
    ),
    RentalItem(
      id: 4,
      name: '모니터',
      category: '전자기기',
      location: '2211호에 배치된 모니터',
      total: 24,
      initialAvailable: 24,
      kind: ProductKind.monitor,
    ),
    RentalItem(
      id: 5,
      name: 'VR 기기',
      category: '실험/기타',
      location: '3401호에 배치된 VR 기기',
      total: 3,
      initialAvailable: 3,
      kind: ProductKind.vr,
    ),
  ],
);
