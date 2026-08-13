enum InjectionBodyView { front, back }

enum InjectionSite {
  abdomenTopLeft,
  abdomenTopRight,
  abdomenBottomLeft,
  abdomenBottomRight,
  loveHandleLeft,
  loveHandleRight,
  thighLeft,
  thighRight,
  armLeft,
  armRight,
  gluteLeft,
  gluteRight,
  custom,
}

extension InjectionBodyViewDetails on InjectionBodyView {
  String get storageValue {
    return switch (this) {
      InjectionBodyView.front => 'front',
      InjectionBodyView.back => 'back',
    };
  }
}

extension InjectionSiteDetails on InjectionSite {
  String get label {
    return switch (this) {
      InjectionSite.abdomenTopLeft => 'Top-left abdomen',
      InjectionSite.abdomenTopRight => 'Top-right abdomen',
      InjectionSite.abdomenBottomLeft => 'Bottom-left abdomen',
      InjectionSite.abdomenBottomRight => 'Bottom-right abdomen',
      InjectionSite.loveHandleLeft => 'Left love handle',
      InjectionSite.loveHandleRight => 'Right love handle',
      InjectionSite.thighLeft => 'Left thigh',
      InjectionSite.thighRight => 'Right thigh',
      InjectionSite.armLeft => 'Left arm',
      InjectionSite.armRight => 'Right arm',
      InjectionSite.gluteLeft => 'Left glute',
      InjectionSite.gluteRight => 'Right glute',
      InjectionSite.custom => 'Custom site',
    };
  }

  String get shortLabel {
    return switch (this) {
      InjectionSite.abdomenTopLeft => 'Top-left',
      InjectionSite.abdomenTopRight => 'Top-right',
      InjectionSite.abdomenBottomLeft => 'Bottom-left',
      InjectionSite.abdomenBottomRight => 'Bottom-right',
      InjectionSite.loveHandleLeft => 'Left love handle',
      InjectionSite.loveHandleRight => 'Right love handle',
      InjectionSite.thighLeft => 'Left thigh',
      InjectionSite.thighRight => 'Right thigh',
      InjectionSite.armLeft => 'Left arm',
      InjectionSite.armRight => 'Right arm',
      InjectionSite.gluteLeft => 'Left glute',
      InjectionSite.gluteRight => 'Right glute',
      InjectionSite.custom => 'Custom',
    };
  }

  String get storageValue {
    return switch (this) {
      InjectionSite.abdomenTopLeft => 'abdomen_top_left',
      InjectionSite.abdomenTopRight => 'abdomen_top_right',
      InjectionSite.abdomenBottomLeft => 'abdomen_bottom_left',
      InjectionSite.abdomenBottomRight => 'abdomen_bottom_right',
      InjectionSite.loveHandleLeft => 'love_handle_left',
      InjectionSite.loveHandleRight => 'love_handle_right',
      InjectionSite.thighLeft => 'thigh_left',
      InjectionSite.thighRight => 'thigh_right',
      InjectionSite.armLeft => 'arm_left',
      InjectionSite.armRight => 'arm_right',
      InjectionSite.gluteLeft => 'glute_left',
      InjectionSite.gluteRight => 'glute_right',
      InjectionSite.custom => 'custom',
    };
  }

  InjectionBodyView get bodyView {
    return switch (this) {
      InjectionSite.abdomenTopLeft ||
      InjectionSite.abdomenTopRight ||
      InjectionSite.abdomenBottomLeft ||
      InjectionSite.abdomenBottomRight ||
      InjectionSite.loveHandleLeft ||
      InjectionSite.loveHandleRight ||
      InjectionSite.thighLeft ||
      InjectionSite.thighRight ||
      InjectionSite.armLeft ||
      InjectionSite.armRight ||
      InjectionSite.custom => InjectionBodyView.front,

      InjectionSite.gluteLeft ||
      InjectionSite.gluteRight => InjectionBodyView.back,
    };
  }

  String get regionId {
    return storageValue;
  }

  static InjectionSite? fromStorageValue(String? value) {
    return switch (value) {
      'abdomen_top_left' => InjectionSite.abdomenTopLeft,
      'abdomen_top_right' => InjectionSite.abdomenTopRight,
      'abdomen_bottom_left' => InjectionSite.abdomenBottomLeft,
      'abdomen_bottom_right' => InjectionSite.abdomenBottomRight,
      'love_handle_left' => InjectionSite.loveHandleLeft,
      'love_handle_right' => InjectionSite.loveHandleRight,
      'thigh_left' => InjectionSite.thighLeft,
      'thigh_right' => InjectionSite.thighRight,
      'arm_left' => InjectionSite.armLeft,
      'arm_right' => InjectionSite.armRight,
      'glute_left' => InjectionSite.gluteLeft,
      'glute_right' => InjectionSite.gluteRight,
      'custom' => InjectionSite.custom,

      // Legacy mappings from the earlier broad site model.
      'left_abdomen' => InjectionSite.abdomenTopLeft,
      'right_abdomen' => InjectionSite.abdomenTopRight,
      'left_thigh' => InjectionSite.thighLeft,
      'right_thigh' => InjectionSite.thighRight,
      'left_arm' => InjectionSite.armLeft,
      'right_arm' => InjectionSite.armRight,
      'left_glute' => InjectionSite.gluteLeft,
      'right_glute' => InjectionSite.gluteRight,

      _ => null,
    };
  }

  static const Set<InjectionSite> defaultSites = {
    InjectionSite.abdomenTopLeft,
    InjectionSite.abdomenTopRight,
    InjectionSite.abdomenBottomLeft,
    InjectionSite.abdomenBottomRight,
  };

  static const Set<InjectionSite> abdomenAndLoveHandleSites = {
    InjectionSite.abdomenTopLeft,
    InjectionSite.abdomenTopRight,
    InjectionSite.abdomenBottomLeft,
    InjectionSite.abdomenBottomRight,
    InjectionSite.loveHandleLeft,
    InjectionSite.loveHandleRight,
  };
}
