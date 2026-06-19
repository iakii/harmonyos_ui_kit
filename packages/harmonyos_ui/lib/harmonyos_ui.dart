/// HarmonyOS UI — A HarmonyOS NEXT style component library for Flutter.
library;

export 'package:flutter/material.dart'
    show
        AdaptiveTextSelectionToolbar,
        AnimatedIcon,
        AnimatedIconData,
        AnimatedIcons,
        Brightness,
        CircleAvatar,
        DatePickerMode,
        DateTimeRange,
        DateUtils,
        DefaultMaterialLocalizations,
        Feedback,
        FlutterLogo,
        HourFormat,
        MaterialLocalizations,
        ReorderableDragStartListener,
        ReorderableListView,
        SelectableDayPredicate,
        SelectableText,
        SelectionArea,
        TextInputAction,
        TextMagnifier,
        TextSelectionTheme,
        TextSelectionThemeData,
        ThemeExtension,
        ThemeMode,
        TooltipTriggerMode,
        TooltipVisibility,
        VisualDensity,
        kElevationToShadow,
        kThemeAnimationDuration;

export 'package:flutter/widgets.dart' hide TextBox, TranslateAnimationSource;

// --- Styles ---
export 'src/styles/color.dart';
export 'src/styles/color_tokens.dart';
export 'src/styles/page_transitions.dart';
export 'src/styles/theme.dart';
export 'src/styles/typography.dart';

// --- Controls: Buttons ---
export 'src/controls/buttons/button.dart';
export 'src/controls/buttons/icon_button.dart';
export 'src/controls/buttons/outlined_button.dart';
export 'src/controls/buttons/text_button.dart';
export 'src/controls/buttons/theme.dart';

// --- Controls: Inputs ---
export 'src/controls/inputs/checkbox.dart';
export 'src/controls/inputs/radio.dart';
export 'src/controls/inputs/toggle_switch.dart';
export 'src/controls/inputs/slider.dart';
export 'src/controls/inputs/rating_bar.dart';

// --- Controls: Form Fields ---
export 'src/controls/form_fields/text_input.dart';
export 'src/controls/form_fields/search_box.dart';
export 'src/controls/form_fields/password_input.dart';
export 'src/controls/form_fields/text_form_input.dart';

// --- Controls: Navigation ---
export 'src/controls/navigation/tab_bar.dart';
export 'src/controls/navigation/app_bar.dart';
export 'src/controls/navigation/bottom_navigation.dart';
export 'src/controls/navigation/navigation_rail.dart';

// --- Controls: Surfaces ---
export 'src/controls/surfaces/card.dart';
export 'src/controls/surfaces/dialog.dart';
export 'src/controls/surfaces/toast.dart';
export 'src/controls/surfaces/bottom_sheet.dart';
export 'src/controls/surfaces/list_item.dart';
export 'src/controls/surfaces/progress.dart';
export 'src/controls/surfaces/loading.dart';
export 'src/controls/surfaces/empty_state.dart';

// --- Controls: Layout ---
export 'src/controls/layout/page.dart';

// --- Controls: Pickers ---
export 'src/controls/pickers/date_picker.dart';
export 'src/controls/pickers/time_picker.dart';

// --- Controls: Utils ---
export 'src/controls/utils/divider.dart';
export 'src/controls/utils/info_label.dart';
export 'src/controls/utils/focus_border.dart';

// --- App ---
export 'src/harmonyos_app.dart';
export 'src/harmonyos_page_route.dart';

// --- Utils ---
export 'src/utils.dart';

// --- Widgets ---
export 'src/widgets/back_icon.dart';
export 'src/widgets/glow/glow.dart';
