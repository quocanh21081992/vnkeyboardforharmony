// entry/src/main/ets/shared/SettingsStore.ets
// Compatibility re-export so both App UI pages and IME pages can import from a stable path.

export {
  PREF_NAME,
  KEY_KEYBOARD_HEIGHT_VP,
  KEY_KEYBOARD_RELOAD_SEQ,
  KEY_NUMBER_ROW_ENABLED,
  DEFAULT_NUMBER_ROW_ENABLED,
  DEFAULT_KEYBOARD_HEIGHT_VP,
  MIN_KEYBOARD_HEIGHT_VP,
  MAX_KEYBOARD_HEIGHT_VP,
  clampKeyboardHeightVp,
  readKeyboardHeightVp,
  writeKeyboardHeightVp,
  readKeyboardReloadSeq,
  bumpKeyboardReloadSeq,
  readNumberRowEnabled,
  writeNumberRowEnabled
} from '../pages/SettingsStore';
