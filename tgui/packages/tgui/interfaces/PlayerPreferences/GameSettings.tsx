import { useBackend } from '../../backend';
import {
  Button,
  ColorBox,
  LabeledList,
  Section,
  Stack,
} from '../../components';
import {
  LoopingSelectionPreference,
  SelectFieldPreference,
  TextFieldPreference,
  ToggleFieldPreference,
} from './FieldPreferences';

const ParallaxNumToString = (integer) => {
  let returnval = '';
  switch (integer) {
    case -1:
      returnval = 'Insane';
      break;
    case 0:
      returnval = 'High';
      break;
    case 1:
      returnval = 'Medium';
      break;
    case 2:
      returnval = 'Low';
      break;
    case 3:
      returnval = 'Disabled';
      break;
    default:
      returnval = 'Error!';
  }
  return returnval;
};

export const GameSettings = (props) => {
  const { act, data } = useBackend<GameSettingData>();
  const { ui_style_color, scaling_method, pixel_size, parallax, is_admin } =
    data;

  // Remember to update this alongside defines
  // todo: unfuck. Bruh why is this being handled in the tsx?
  const TTSRadioSetting = ['sl', 'squad', 'command', 'hivemind', 'all'];
  const TTSRadioSettingToBitfield = {
    sl: 1 << 0,
    squad: 1 << 1,
    command: 1 << 2,
    all: 1 << 3,
    hivemind: 1 << 4,
  };
  const TTSRadioSettingToName = {
    sl: 'Squad Leader',
    squad: 'Squad',
    command: 'Command/Hive Leader',
    hivemind: 'Hivemind',
    all: 'All Channels',
  };

  return (
    <Section title="Game Settings">
      <Stack fill>
        <Stack.Item grow>
          <Section title="Window settings">
            <LabeledList>
              <ToggleFieldPreference
                label="Window flashing"
                value="windowflashing"
                action="windowflashing"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Allows native taskbar flashing for important events."
              />
              <ToggleFieldPreference
                label="Unique action behaviour"
                value="unique_action_use_active_hand"
                action="unique_action_use_active_hand"
                leftLabel={'Use on active hand'}
                rightLabel={'Use on both hands'}
                tooltip="Governs if unique action will only use on your active hand or also try to do a unique action with your offhand."
              />
              <ToggleFieldPreference
                label="Mute xeno health alert messages"
                value="mute_xeno_health_alert_messages"
                action="mute_xeno_health_alert_messages"
                leftLabel={'Muted'}
                rightLabel={'Enabled'}
                tooltip="Governs if you receive alerts for low health xenos when playing as a xeno."
              />
              <SelectFieldPreference
                label="Play Text-to-Speech"
                value="sound_tts"
                action="sound_tts"
                tooltip="Enables receiving TTS sounds."
              />
              <TextFieldPreference
                label="Text to speech volume"
                value="volume_tts"
                tooltip="The volume of TTS sounds."
              />
              <LabeledList.Item
                label={'Text to Speech radio configuration'}
                tooltip="Who you can hear radio/hivemind TTS from."
              >
                {TTSRadioSetting.map((setting) => (
                  <Button.Checkbox
                    inline
                    key={setting}
                    content={TTSRadioSettingToName[setting]}
                    checked={
                      TTSRadioSettingToBitfield[setting] &
                      data['radio_tts_flags']
                    }
                    onClick={() =>
                      act('toggle_radio_tts_setting', {
                        newsetting: setting,
                      })
                    }
                  />
                ))}
              </LabeledList.Item>
              <ToggleFieldPreference
                label="Accessible TGUI themes"
                value="accessible_tgui_themes"
                action="accessible_tgui_themes"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Tries to use more accessible or default TGUI themes/layouts wherever possible/applied."
              />
              <ToggleFieldPreference
                label="Fullscreen mode"
                value="fullscreen_mode"
                action="fullscreen_mode"
                leftLabel={'Fullscreen'}
                rightLabel={'Windowed'}
                tooltip="Governs if the game is in fullscreen, hiding your native taskbar/window top bar and letting it take up your entire display."
              />
              <ToggleFieldPreference
                label="TGUI Window Mode"
                value="tgui_fancy"
                action="tgui_fancy"
                leftLabel={'Fancy (default)'}
                rightLabel={'Compatible (slower)'}
                tooltip="Governs if TGUI web views will use a baked-in top bar or use the native top bar. Compatible is only required for extremely old operating systems/computers."
              />
              <ToggleFieldPreference
                label="TGUI Window Placement"
                value="tgui_lock"
                action="tgui_lock"
                leftLabel={'Free (default)'}
                rightLabel={'Primary monitor'}
                tooltip="Governs if TGUI web views can move between monitors or only stay in your primary monitor."
              />
              <ToggleFieldPreference
                label="TGUI Input boxes"
                value="tgui_input"
                action="tgui_input"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if input boxes will open in a TGUI web view or BYOND native alert."
              />
              <ToggleFieldPreference
                label="TGUI Input Buttons"
                value="tgui_input_big_buttons"
                action="tgui_input_big_buttons"
                leftLabel={'Normal'}
                leftValue={0}
                rightLabel={'Large'}
                rightValue={1}
                tooltip="The size of buttons in TGUI input boxes."
              />
              <ToggleFieldPreference
                label="TGUI Input Buttons placement"
                value="tgui_input_buttons_swap"
                action="tgui_input_buttons_swap"
                leftLabel={'Submit/Cancel'}
                rightLabel={'Cancel/Submit'}
                tooltip="The order that input buttons will use in TGUI input boxes."
              />
              <ToggleFieldPreference
                label="Tooltips"
                value="tooltips"
                action="tooltips"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if HTML web view tooltips can appear, for example when mousing over status alerts. No effect on TGUI."
              />
              <TextFieldPreference label={'FPS'} value={'clientfps'} />
              <ToggleFieldPreference
                label="Auto Fit viewport"
                value="auto_fit_viewport"
                action="auto_fit_viewport"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if the game will automatically run Fit Viewport when your view range changes."
              />
              <ToggleFieldPreference
                label="Auto interact with Deployables"
                value="autointeractdeployablespref"
                action="autointeractdeployablespref"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if you will automatically use and man deployables after you finish setting them up."
              />
              <ToggleFieldPreference
                label="Use directional attacks"
                value="directional_attacks"
                action="directional_attacks"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if directional melee attacks for people not on your faction are enabled. Click in a direction to attack people adjacent to you."
              />
            </LabeledList>
          </Section>
        </Stack.Item>
        <Stack.Item grow>
          <Section title="Message settings">
            <LabeledList>
              <ToggleFieldPreference
                label="Runechat bubbles"
                value="chat_on_map"
                action="chat_on_map"
                leftValue={1}
                leftLabel={'Enabled'}
                rightValue={0}
                rightLabel={'Disabled'}
                tooltip="Governs if above-head messages are enabled."
              />
              <TextFieldPreference
                label="Runechat character limit"
                value="max_chat_length"
                tooltip="Maximum length for a runechat message before it is truncated."
              />
              <ToggleFieldPreference
                label="Show non-mob runechat"
                value="see_chat_non_mob"
                action="see_chat_non_mob"
                leftValue={1}
                leftLabel={'Enabled'}
                rightValue={0}
                rightLabel={'Disabled'}
                tooltip="Governs if runechat can appear for non-mobs (vending machines, tactical binoculars, etc)."
              />
              <ToggleFieldPreference
                label="Show emotes in runechat"
                value="see_rc_emotes"
                action="see_rc_emotes"
                leftValue={1}
                leftLabel={'Enabled'}
                rightValue={0}
                rightLabel={'Disabled'}
                tooltip="Governs if runechat can appear for emotes."
              />
              <ToggleFieldPreference
                label="Show typing indicator"
                value="show_typing"
                action="show_typing"
                leftValue={1}
                leftLabel={'Enabled'}
                rightValue={0}
                rightLabel={'Disabled'}
                tooltip="Governs if your sprite will gain a typing indicator when you use TGUI say."
              />
              <ToggleFieldPreference
                label="Show self combat messages"
                value="mute_self_combat_messages"
                action="mute_self_combat_messages"
                leftValue={0}
                leftLabel={'Enabled'}
                rightValue={1}
                rightLabel={'Disabled'}
              />
              <ToggleFieldPreference
                label="Show others combat messages"
                value="mute_others_combat_messages"
                action="mute_others_combat_messages"
                leftValue={0}
                leftLabel={'Enabled'}
                rightValue={1}
                rightLabel={'Disabled'}
              />
              <ToggleFieldPreference
                label="Show xeno rank"
                value="show_xeno_rank"
                action="show_xeno_rank"
                leftValue={1}
                leftLabel={'Enabled'}
                rightValue={0}
                rightLabel={'Disabled'}
                tooltip="Enables your xeno name being prefixed with a rank based on your playtime."
              />
            </LabeledList>
          </Section>
        </Stack.Item>
      </Stack>
      <Stack>
        <Stack.Item grow>
          <Section title="UI settings">
            <LabeledList>
              <SelectFieldPreference
                label={'UI Style'}
                value={'ui_style'}
                action={'ui'}
                tooltip="The viewport UI style. Applies when you respawn."
              />
              <TextFieldPreference
                label={'UI Color'}
                value={'ui_style_color'}
                noAction
                extra={
                  <>
                    <ColorBox color={ui_style_color} mr={1} />
                    <Button icon="edit" onClick={() => act('uicolor')} />
                  </>
                }
              />
              <TextFieldPreference
                label={'UI Opacity'}
                value={'ui_style_alpha'}
                action={'uialpha'}
                tooltip="The opacity of the viewport UI."
              />
              <ToggleFieldPreference
                label="Widescreen mode"
                value="widescreenpref"
                action="widescreenpref"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if the viewport uses widescreen. Allows for slightly increased horizontal FOV and looks less jarring on modern aspect ratios."
              />
              <ToggleFieldPreference
                label="Radial medical wheel"
                value="radialmedicalpref"
                action="radialmedicalpref"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if medical actions will use a radial wheel for choosing limbs or use your targeted limb."
              />
              <ToggleFieldPreference
                label="Radial stacks wheel"
                value="radialstackspref"
                action="radialstackspref"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if material stacks will default to opening a radial wheel or window for viewing recipes."
              />
              <ToggleFieldPreference
                label="Radial laser gun wheel"
                value="radiallasersgunpref"
                action="radiallasersgunpref"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if laser guns and other weapons with multiple modes will use a radial wheel for changing modes or simply switch to the next mode over on unique action."
              />
              <LoopingSelectionPreference
                label="Scaling Method"
                value={scaling_method}
                action="scaling_method"
                tooltip="How the viewport will scale for different sizes. Distort looks 100% clear but may impact the look of sprites depending on how large the game viewport is."
              />
              <LoopingSelectionPreference
                label="Pixel Size Scaling"
                value={pixel_size}
                action="pixel_size"
                tooltip="What size pixels should be displayed as."
              />
              <LoopingSelectionPreference
                label="Parallax"
                value={ParallaxNumToString(parallax)}
                action="parallax"
                tooltip="The quality level of space parallax."
              />
            </LabeledList>
          </Section>
        </Stack.Item>
        <Stack.Item grow>
          <Section title="Sound settings">
            <LabeledList>
              <ToggleFieldPreference
                label="Toggle admin music"
                value="toggle_admin_music"
                action="toggle_admin_music"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if you can hear sounds played by admins."
              />
              <ToggleFieldPreference
                label="Toggle ambience sound"
                value="toggle_ambience_sound"
                action="toggle_ambience_sound"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if you can hear SS13 or groundmap ambience."
              />
              <ToggleFieldPreference
                label="Toggle lobby music"
                value="toggle_lobby_music"
                action="toggle_lobby_music"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if you can hear lobby music."
              />
              <ToggleFieldPreference
                label="Toggle instruments sound"
                value="toggle_instruments_sound"
                action="toggle_instruments_sound"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if you can hear instruments at all."
              />
              <ToggleFieldPreference
                label="Toggle weather sound"
                value="toggle_weather_sound"
                action="toggle_weather_sound"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if you can hear ground map weather."
              />
              <ToggleFieldPreference
                label="Toggle round end sounds"
                value="toggle_round_end_sounds"
                action="toggle_round_end_sounds"
                leftLabel={'Enabled'}
                rightLabel={'Disabled'}
                tooltip="Governs if you can hear jingles when the server restarts or shuts down."
              />
            </LabeledList>
          </Section>
        </Stack.Item>
      </Stack>
      {!!is_admin && (
        <Stack>
          <Stack.Item grow>
            <Section title="Staff settings">
              <LabeledList>
                <ToggleFieldPreference
                  label="Fast MC Refresh"
                  value="fast_mc_refresh"
                  action="fast_mc_refresh"
                  leftLabel={'Enabled'}
                  rightLabel={'Disabled'}
                  tooltip="Governs if the MC tab refreshes super fast. Not recommended except for debugging purposes."
                />
                <ToggleFieldPreference
                  label="Split admin tabs"
                  value="split_admin_tabs"
                  action="split_admin_tabs"
                  leftLabel={'Enabled'}
                  rightLabel={'Disabled'}
                  tooltip="When enabled, staff commands will be split into multiple tabs (Admin/Fun/etc). Otherwise, non-debug commands will remain in one statpanel tab."
                />
                <ToggleFieldPreference
                  label="Toggle ticket sounds"
                  value="toggle_adminhelp_sound"
                  action="toggle_adminhelp_sound"
                  leftLabel={'Enabled'}
                  rightLabel={'Disabled'}
                  tooltip="Governs if you can hear ahelp/mhelp sounds."
                />
                <ToggleFieldPreference
                  label="Hear LOOC from anywhere"
                  value="hear_looc_anywhere_as_staff"
                  action="hear_looc_anywhere_as_staff"
                  leftLabel={'Enabled'}
                  rightLabel={'Disabled'}
                  tooltip="Enables hearing LOOC from anywhere in any situation. For Mentors, this setting is only relevant when observing."
                />
              </LabeledList>
            </Section>
          </Stack.Item>
        </Stack>
      )}
    </Section>
  );
};
