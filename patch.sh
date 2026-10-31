#!/bin/bash

mkdir -p chrome/android/java/res_titanium_base
cp $SCRIPT_DIR/res/drawable/themed_app_icon.xml chrome/android/java/res_titanium_base/drawable/themed_app_icon.xml
for icon in $(find chrome/android/java/res_titanium_base -type f -name '*.png'); do convert $icon -fill navy -tint 36 $icon && $SCRIPT_DIR/res/icon.sh $icon; done
sed -i 's|<application |<application android:extractNativeLibs="false" |' chrome/android/java/AndroidManifest.xml
sed -i 's|<data android:mimeType="message/rfc822"/>|<data android:mimeType="message/rfc822"/><data android:mimeType="application/pdf"/>|' chrome/android/java/AndroidManifest.xml
sed -i '/com.google.ar.core.min_apk_version/d' third_party/arcore-android-sdk-client/AndroidManifest_basesplit.xml
# sed -i 's|Google LLC|jqssun, Google LLC|' chrome/browser/ui/android/strings/android_chrome_strings.grd

mkdir -p $SCRIPT_DIR/extensions/dist
mkdir -p titanium/dist
cp -r $SCRIPT_DIR/extensions/dist titanium/
cp $SCRIPT_DIR/extensions/stage_bundled_extensions.inc titanium/dist/
sed -i 's|"//components/privacy_sandbox/privacy_sandbox_attestations/preload:privacy_sandbox_attestations_assets",|&"//titanium/dist:extension_assets",|' chrome/android/BUILD.gn
sed -i 's|if (!base::PathService::Get(base::DIR_MODULE, \&cur)) {|if (!base::PathService::Get(chrome::DIR_USER_DATA, \&cur)) {|' chrome/common/chrome_paths.cc
sed -i 's|#include "extensions/buildflags/buildflags.h"|&\n#include "titanium/dist/stage_bundled_extensions.inc"|' chrome/browser/extensions/external_pref_loader.cc
sed -i 's|ReadStandaloneExtensionPrefFiles(prefs);|&StageBundledExtensions(base_path_id_, base_path_, prefs);|' chrome/browser/extensions/external_pref_loader.cc
sed -i 's|if (extension.location() == mojom::ManifestLocation::kCommandLine) {|if (extension.location() == mojom::ManifestLocation::kExternalPref) return false;\n&|' chrome/browser/extensions/extension_safety_check_utils.cc

sed -i 's|if (!_omit_dex) {|if (_is_base_module \&\& !_omit_dex) {|' build/config/android/rules.gni
sed -i '/safelyRemovePreference(prefFragment/d' titanium/chromium_src/chrome/browser/language/android/java/src/org/chromium/chrome/browser/language/settings/LanguageSettingsExt.java # language
sed -i '/safelyRemovePreference($/{N;/PREF_JAVASCRIPT_OPTIMIZER/d}' titanium/chromium_src/chrome/android/java/src/org/chromium/chrome/browser/privacy/settings/PrivacySettingsExt.java # optimizer
sed -i 's|initPreferences(PreferenceFragmentCompat prefFragment, Profile profile) {|& SettingsExtUtils.safelyRemovePreference(prefFragment, PREF_OPEN_LINKS_IN_INCOGNITO);|' titanium/chromium_src/chrome/android/java/src/org/chromium/chrome/browser/privacy/settings/PrivacySettingsExt.java # remove open links in incognito pref
sed -i 's|public static boolean shouldOpenLinksInIncognito() {|public static boolean shouldOpenLinksInIncognito() { if (true) return false; |' titanium/chromium_src/chrome/android/java/src/org/chromium/chrome/browser/TabPreferencesUtils.java # disable open links in incognito
sed -i 's|if (!Intent\.ACTION_VIEW\.equals(intent\.getAction())) {|if (!Intent.ACTION_VIEW.equals(intent.getAction()) \|\| !android.webkit.URLUtil.isNetworkUrl(IntentHandler.getUrlFromIntent(intent))) {|' titanium/chromium_src/chrome/android/java/src/org/chromium/chrome/browser/LaunchIntentDispatcherHooks.java # scheme guard
sed -i 's|if (urlFromIntent == null) {|if (!android.webkit.URLUtil.isNetworkUrl(urlFromIntent)) {|' titanium/chromium_src/chrome/android/java/src/org/chromium/chrome/browser/LaunchIntentDispatcherHooks.java # scheme guard
sed -i 's|static Intent maybeModifyCustomTabIntents(Context context, Intent intent) {|static Intent maybeModifyCustomTabIntents(Context context, Intent intent) { if (!android.webkit.URLUtil.isNetworkUrl(IntentHandler.getUrlFromIntent(intent))) { return intent; }|' titanium/chromium_src/chrome/android/java/src/org/chromium/chrome/browser/LaunchIntentDispatcherHooks.java # scheme guard
sed -i 's|readBoolean(getSettingsPreferenceKey(moduleType), true)|readBoolean(getSettingsPreferenceKey(moduleType), !HomeModulesUtils.belongsToEducationalTipModule(moduleType))|' chrome/browser/magic_stack/android/java/src/org/chromium/chrome/browser/magic_stack/HomeModulesConfigManager.java # ntp
sed -i 's|private static boolean verifyPackage(Context ctx, String pkgName, byte\[\] sha256CertDigestBytes) {|& if (true) return false; |' titanium/android_config/parser/java/src/app/titanium/config/TitaniumConfParser.java # config parser

# sed -i 's|int ExpirationMilestoneForFlag(const char\* flag) {|int ExpirationMilestoneForFlag(const char* flag) { if ((true)) return -1;|' chrome/browser/unexpire_flags.cc
for flag in "align-wakeups" "android-bottom-bar" "cct-open-in-browser-button-if-allowed-by-embedder" "darken-websites-checkbox-in-themes-setting" "enable-accessibility-sequential-focus" "enforce-incognito-isolation" "inline-pdf-v2" "jump-start-omnibox" "lock-controls-on-tablets-v2" "offline-auto-fetch" "use-fullscreen-insets-api"; do
    sed -i "/\"name\": \"$flag\"/,/}/ s/\"expiry_milestone\": [0-9]\+/\"expiry_milestone\": -1/" chrome/browser/flag-metadata.json
done
sed -i 's|newFlag(OmniboxFeatureList.OMNIBOX_SITE_SEARCH, FeatureState.ENABLED_IN_TEST);|newFlag(OmniboxFeatureList.OMNIBOX_SITE_SEARCH, FeatureState.ENABLED_IN_PROD);|' components/omnibox/common/android/java/src/org/chromium/components/omnibox/OmniboxFeatures.java # search
sed -i 's|BASE_FEATURE(kOmniboxSiteSearch, DISABLED);|BASE_FEATURE(kOmniboxSiteSearch, ENABLED);|' components/omnibox/common/omnibox_features.cc # search

if version_lt "$VERSION" "156.0.8000.0"; then
sed -i '/#if BUILDFLAG(IS_DESKTOP_ANDROID)/{
a\
feature_overrides.EnableFeature(chrome::android::kSubmenusInAppMenu);\
feature_overrides.EnableFeature(features::kAndroidDevToolsFrontend);\
feature_overrides.DisableFeature(kAndroidMediaPicker);\
feature_overrides.DisableFeature(features::kUserMediaScreenCapturing);\
feature_overrides.DisableFeature(media::kAndroidEnableBackgroundMediaCapturing);\
feature_overrides.EnableFeature(media::kAutoPictureInPictureAndroid);\
feature_overrides.EnableFeature(media::kContextMenuPictureInPictureAndroid);\
feature_overrides.EnableFeature(chrome::android::kLoadAllTabsAtStartup);\
feature_overrides.EnableFeature(chrome::android::kChromeNativeUrlOverriding);\
feature_overrides.DisableFeature(chrome::android::kAndroidHubSearch);\
feature_overrides.DisableFeature(chrome::android::kTabGroupParityAndroid);\
#if 0
d}' chrome/browser/chrome_browser_field_trials.cc
else
sed -i '/#if BUILDFLAG(IS_DESKTOP_ANDROID)/{
a\
feature_overrides.EnableFeature(chrome::android::kSubmenusInAppMenu);\
feature_overrides.EnableFeature(features::kAndroidDevToolsFrontend);\
feature_overrides.DisableFeature(kAndroidMediaPicker);\
feature_overrides.DisableFeature(features::kUserMediaScreenCapturing);\
feature_overrides.DisableFeature(media::kAndroidEnableBackgroundMediaCapturing);\
feature_overrides.EnableFeature(media::kAutoPictureInPictureAndroid);\
feature_overrides.EnableFeature(media::kContextMenuPictureInPictureAndroid);\
feature_overrides.EnableFeature(chrome::android::kLoadAllTabsAtStartup);\
feature_overrides.EnableFeature(chrome::android::kChromeNativeUrlOverriding);\
#if 0
d}' chrome/browser/chrome_browser_field_trials.cc
fi
sed -i '/^bool ShouldFallbackToSWIfGLES3NotSupported() {$/,/^}$/ s|^  return true;$|  return false;|' ui/gl/gl_features.cc # virt

# accessibility
sed -i 's|ChromeAccessibilityUtil.get().isAccessibilityEnabled()|org.chromium.ui.accessibility.AccessibilityState.isComplexUserInteractionServiceEnabled() \|\| org.chromium.ui.accessibility.AccessibilityState.isTouchExplorationEnabled()|' chrome/android/java/src/org/chromium/chrome/browser/tab/TabStateBrowserControlsVisibilityDelegate.java
sed -i 's|AccessibilityState.isPerformGesturesEnabled()|(AccessibilityState.isComplexUserInteractionServiceEnabled() \|\| AccessibilityState.isTouchExplorationEnabled())|' chrome/browser/ui/messages/android/java/src/org/chromium/chrome/browser/ui/messages/snackbar/SnackbarManager.java

# dev
sed -i 's|buildTaskManagerItem() {|buildTaskManagerItem() { if (true) return null;|' chrome/android/java/src/org/chromium/chrome/browser/tabbed_mode/MoreToolsItemBuilder.java
if version_lt "$VERSION" "156.0.8060.0"; then
sed -i 's|!DeviceFormFactor.isNonMultiDisplayContextOnTablet(mContext)|(false \&\& &)|' chrome/android/java/src/org/chromium/chrome/browser/tabbed_mode/MoreToolsItemBuilder.java
sed -i 's|boolean shouldShowDeveloperMenu() {|boolean shouldShowDeveloperMenu() { if (true) return DevToolsWindowAndroid.isDevToolsAllowedFor(getProfile(), mItemDelegate.getWebContents());|' chrome/android/java/src/org/chromium/chrome/browser/contextmenu/ChromeContextMenuPopulator.java
else
sed -i 's|DeviceFormFactor.isNonMultiDisplayContextOnTablet(context)|(true \|\| &)|' chrome/browser/devtools/android/java/src/org/chromium/chrome/browser/devtools/DevToolsWindowAndroid.java
fi
sed -i 's|TabUtils.isUsingDesktopUserAgent(mItemDelegate.getWebContents())|(true \|\| TabUtils.isUsingDesktopUserAgent(mItemDelegate.getWebContents()))|' chrome/android/java/src/org/chromium/chrome/browser/contextmenu/ChromeContextMenuPopulator.java

# dev: incognito
sed -i 's|intent.putExtra(DevToolsActivity.WEB_CONTENTS_KEY, webContents);|&intent.putExtra("org.chromium.chrome.browser.devtools.DevTools.Incognito", webContents.isIncognito());|' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java
sed -i 's|TabModel tabModel = getTabModelSelector().getModel(false);|TabModel tabModel = getTabModelSelector().getModel(getIntentDataProvider().isOffTheRecord());|' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsActivity.java
sed -i 's|import org.chromium.chrome.browser.flags.ActivityType;|&\nimport org.chromium.chrome.browser.flags.CustomTabProfileType;|' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsIntentDataProvider.java
sed -i '/^public class DevToolsIntentDataProvider extends BrowserServicesIntentDataProvider {$/a\ @Override public @CustomTabProfileType int getCustomTabMode() { return mIntent.getBooleanExtra("org.chromium.chrome.browser.devtools.DevTools.Incognito", false) ? CustomTabProfileType.INCOGNITO : CustomTabProfileType.REGULAR; }' chrome/android/java/src/org/chromium/chrome/browser/devtools/DevToolsIntentDataProvider.java
sed -i 's|case CustomTabProfileType.INCOGNITO:|& if (getIntentDataProvider().getActivityType() == ActivityType.DEV_TOOLS) return null;|' chrome/android/java/src/org/chromium/chrome/browser/customtabs/BaseCustomTabActivity.java

# dev: viewport
sed -i 's|<meta charset="utf-8">|&\n<meta name="viewport" content="width=device-width">|' third_party/devtools-frontend/src/front_end/entrypoint_template.html
sed -i '$a@media (max-width: 600px) { .settings-window-title, .tabbed-pane-header-tab-title { display: none; } .tabbed-pane-shadow.vertical-tab-layout .tabbed-pane-header-tabs { width: auto; } }' third_party/devtools-frontend/src/front_end/panels/settings/settingsScreen.css
sed -i 's|document_->GetSettings() ? |document_->GetSettings() \&\& !document_->IsViewSource() ? |' third_party/blink/renderer/core/css/resolver/viewport_style_resolver.cc
sed -i 's|kViewSourceLineWrappingEnabled, false|kViewSourceLineWrappingEnabled, true|' chrome/browser/prefs/browser_prefs.cc

# ext: viewport
sed -i 's|<meta name="color-scheme" content="light dark">|&\n<meta name="viewport" content="width=device-width">|' chrome/browser/resources/extensions/extensions.html
sed -i 's|--extensions-card-width: 400px;|--extensions-card-width: 96%;|' chrome/browser/resources/extensions/item_list.css # card width
sed -i 's|--cr-toolbar-field-width: 680px;|--cr-toolbar-field-width: 96%;|' chrome/browser/resources/extensions/shared_vars.css # page content
sed -i 's|padding: 24px 60px 64px;|padding: 24px 0 64px;|' chrome/browser/resources/extensions/item_list.css # content wrapper
sed -i 's|touch-action: none;|touch-action: pan-y;|' chrome/browser/resources/extensions/toggle_row.css # scroll

# ext: mv2
sed -i 's|uncompiled_sources_ = \[|&\n  "browser_action.json",\n  "page_action.json",|' chrome/common/extensions/api/api_sources.gni
sed -i 's/api::webstore_private::MV2DeprecationStatus::kHardDisable)));/api::webstore_private::MV2DeprecationStatus::kNone)));/' extensions/browser/api/webstore_private/webstore_private_api.cc
sed -i 's/bool g_allow_mv2_for_testing = false;/bool g_allow_mv2_for_testing = true;/' extensions/browser/manifest_v2_handler.cc

# ext: off store
sed -i '/^bool OffStoreInstallAllowedByPrefs(/a\if (const auto\& o = item.GetRequestInitiator(); o \&\& o->scheme() == "chrome-extension") return true; for (const char* d : {"addons.opera.com", "operacdn.com", "microsoftedge.microsoft.com", "edge.microsoft.com", "delivery.mp.microsoft.com"}) if (item.GetURL().DomainIs(d) || item.GetReferrerUrl().DomainIs(d)) return true;' chrome/browser/download/download_crx_util.cc
# sed -i 's/bool g_allow_offstore_install_for_testing = false;/bool g_allow_offstore_install_for_testing = true;/' chrome/browser/download/download_crx_util.cc
sed -i 's|public static void maybeDefaultEnableWindowSetting(Activity activity, Profile profile) {$|&WebsitePreferenceBridge.setContentSettingCustomScope(profile, ContentSettingsType.REQUEST_DESKTOP_SITE, "[*.]chromewebstore.google.com", SITE_WILDCARD, ContentSetting.ALLOW);|' chrome/browser/ui/android/desktop_site/java/src/org/chromium/chrome/browser/desktop_site/DesktopSiteUtils.java # desktop

# ext: toolbar
sed -i '/<ViewStub/{N;N;N;N;N;N; /optional_button_stub/a\
        <ViewStub\
            android:id="@+id/extensions_toolbar_container_stub"\
            android:inflatedId="@+id/extensions_toolbar_container"\
            android:layout_width="wrap_content"\
            android:layout_height="?attr/toolbarButtonHeight"\
            android:layout_marginVertical="?attr/toolbarButtonMarginVertical" />
}' chrome/browser/ui/android/toolbar/java/res/layout/toolbar_phone.xml
sed -i 's|(ToolbarTablet) mToolbarLayout,|mToolbarLayout,|' chrome/android/java/src/org/chromium/chrome/browser/toolbar/ToolbarManager.java
sed -i '/\/\/ Draw the signin button if visible./i\        { View extContainer = findViewById(R.id.extensions_toolbar_container); if (extContainer != null \&\& extContainer.getVisibility() != View.GONE \&\& extContainer.getWidth() != 0) { canvas.save(); ViewUtils.translateCanvasToView(mToolbarButtonsContainer, extContainer, canvas); extContainer.draw(canvas); canvas.restore(); } }' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/top/ToolbarPhone.java

# ext: popup
sed -i '/public class RecyclerViewDelegate {$/a\public View getContainerView() { return mContainer; }' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionActionListCoordinator.java
sed -i '/private void showPopupOnAnchor() {/,/private void closePopup() {/ s|if (buttonView == null) {|if (false) {|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionActionListMediator.java # scoped to showPopupOnAnchor
sed -i 's|buttonView.setIsPressed(true);|if (buttonView != null) buttonView.setIsPressed(true);|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionActionListMediator.java
sed -i '/[[:space:]]mWindowAndroid,/!b;n;s|[[:space:]]buttonView,|buttonView != null ? buttonView : mRecyclerViewDelegate.getContainerView(),|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionActionListMediator.java # set popup anchor

# ext: fullscreen
sed -i 's|#include "base/android/jni_string.h"|&\n#include "ui/base/device_form_factor.h"|' chrome/browser/ui/android/extensions/extension_action_popup_contents.cc
sed -i 's|render_frame_host->GetView()->EnableAutoResize(kMinSize, kMaxSize);|if (ui::GetDeviceFormFactor() == ui::DEVICE_FORM_FACTOR_PHONE) return;\n&|' chrome/browser/ui/android/extensions/extension_action_popup_contents.cc
sed -i '/^void ExtensionActionPopupContents::OnLoaded() {$/,/^}$/ s|^}$|if (ui::GetDeviceFormFactor() == ui::DEVICE_FORM_FACTOR_PHONE) Java_ExtensionActionPopupContents_resizeDueToAutoResize(AttachCurrentThread(), java_object_, 100000, 100000);\n}|' chrome/browser/ui/android/extensions/extension_action_popup_contents.cc
sed -i 's|mPopupWindowAndroid =$|{ View decor = activity.getWindow().getDecorView(); webContents.setSize(decor.getWidth(), decor.getHeight()); }\n&|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionActionPopup.java

# ext: pin
sed -i '/Pref.PIN_EXTENSIONS_MENU_BUTTON, this::updateMenuButtonPinState);$/a\if (!mPrefService.getBoolean(Pref.PIN_EXTENSIONS_MENU_BUTTON)) { mContainer.findViewById(R.id.extensions_menu_button).setVisibility(View.GONE); }' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java
sed -i '/"ExtensionsToolbarCoordinatorImpl.requestLayoutWithViewUtils()");$/a\if (!isMenuButtonPinned()) { mContainer.findViewById(R.id.extensions_menu_button).setVisibility(View.GONE); }' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/extensions/ExtensionsToolbarCoordinatorImpl.java

# ext: incognito
sed -i 's|if (!context->IsOffTheRecord()) {|if (true) {|' extensions/browser/process_manager.cc
sed -i 's|public static boolean shouldOpenIncognitoAsWindow() {|public static boolean shouldOpenIncognitoAsWindow() { if (true) return false; |' chrome/browser/incognito/android/java/src/org/chromium/chrome/browser/incognito/IncognitoUtils.java

# ext: priority
sed -i 's|private @ChildProcessImportance int mEffectiveImportance;$|&private final boolean mIsExtensionProcess;|' content/public/android/java/src/org/chromium/content/browser/ChildProcessLauncherHelperImpl.java
sed -i 's|^ *if (!ApplicationStatus.isInitialized()) return;$|mIsExtensionProcess = Arrays.asList(commandLine).contains("--extension-process"); if (mIsExtensionProcess) mEffectiveImportance = ChildProcessImportance.IMPORTANT;&|' content/public/android/java/src/org/chromium/content/browser/ChildProcessLauncherHelperImpl.java
sed -i 's|@ChildProcessImportance int importance) {$|&if (mIsExtensionProcess) importance = ChildProcessImportance.IMPORTANT;|' content/public/android/java/src/org/chromium/content/browser/ChildProcessLauncherHelperImpl.java

# ext: settings
sed -i 's|"platforms": \["win", "mac"\]|"platforms": ["win", "mac", "desktop_android"]|' chrome/common/extensions/api/_manifest_features.json

# ext: dialog
sed -i 's|.with(ModalDialogProperties.FILTER_TOUCH_FOR_SECURITY, true)|.with(ModalDialogProperties.FILTER_TOUCH_FOR_SECURITY, false)|' chrome/browser/ui/android/extensions/java/src/org/chromium/chrome/browser/ui/extensions/ExtensionInstallDialogBridge.java

# ext: locale
sed -i 's|while (!(locale_path = locales.Next()).empty()) {|&if (locale_path.IsContentUri()) { locale_path = path.Append(locales.GetInfo().GetName()); }|' extensions/common/manifest_handlers/default_locale_handler.cc
sed -i 's|while (!(locale_folder = locales.Next()).empty()) {|&if (locale_folder.IsContentUri()) { locale_folder = locale_path.Append(locales.GetInfo().GetName()); }|' extensions/common/extension_l10n_util.cc
sed -i '/extension_l10n_util::ValidateExtensionLocales($/,/error) &&$/{s|extension_l10n_util::ValidateExtensionLocales(|(extension_path_.IsVirtualDocumentPath() \|\| &|;s|error) &&|error)) \&\&|}' extensions/browser/unpacked_installer.cc

# ext: ntp
if version_lt "$VERSION" "152.0.7969.0"; then
sed -i 's|import org.chromium.chrome.browser.url_constants.UrlConstantResolverFactory;|&\nimport org.chromium.chrome.browser.url_constants.UrlOverrideUtils;|' chrome/android/java/src/org/chromium/chrome/browser/ChromeTabbedActivity.java
sed -i 's|if (isTabNtp \&\& !currentTab.isNativePage()) {|if (isTabNtp \&\& !currentTab.isNativePage() \&\& !UrlOverrideUtils.isNtpOverrideEnabled() \&\& !UrlOverrideUtils.isWebUiNtpOverrideEnabled()) {|' chrome/android/java/src/org/chromium/chrome/browser/ChromeTabbedActivity.java
else
sed -i 's|if (isTabNtp \&\& !currentTab.isNativePage() \&\& !isTabWebUiNtp) {|if (isTabNtp \&\& !currentTab.isNativePage() \&\& !isTabWebUiNtp \&\& !UrlOverrideUtils.isNtpOverrideEnabled()) {|' chrome/android/java/src/org/chromium/chrome/browser/ChromeTabbedActivity.java
fi

# ext: app
sed -i 's|^  "app": {$|&\n    "platforms": ["chromeos", "linux", "mac", "win"],|' chrome/common/extensions/api/_api_features.json

# desktop: omnibox
sed -i 's/is_desktop_android = !!BUILDFLAG(IS_DESKTOP_ANDROID);/is_desktop_android = false;/' components/omnibox/browser/zero_suggest_verbatim_match_provider.cc
sed -i 's/is_android_mobile = is_android_any \&\& !is_android_desktop;/is_android_mobile = is_android_any \&\& is_android_desktop;/' components/omnibox/browser/autocomplete_result.cc
# sed -i 's|OmniboxCapabilities.hasDesktopExperience(context)|true|g' chrome/browser/ui/android/omnibox/java/src/org/chromium/chrome/browser/omnibox/FuseboxSessionState.java

# crbug.com/406136787: load unpacked
sed -i 's|assert treeId.equals(documentId);|&\n if ("com.android.externalstorage.documents".equals(mAuthority)) { String fastId = mRelativePath.isEmpty() ? treeId : (treeId.endsWith(":") ? treeId + mRelativePath : treeId + "/" + mRelativePath); Uri fast = DocumentsContract.buildDocumentUriUsingTree(tree, fastId); return contentUriExists(fast) ? fast : null; }|' base/android/java/src/org/chromium/base/VirtualDocumentPath.java

# crbug.com/431004500: incognito uaf
sed -i '/for (int i = 0; i < tab_list->GetTabCount(); ++i) {/i if (!tab_list) { continue; }' chrome/browser/extensions/api/tabs/tabs_api.cc

# crbug.com/40274462: incognito uaf
sed -i '/CONTENT_EXPORT static WebContents\* FromRenderFrameHost(RenderFrameHost\* rfh);/a\CONTENT_EXPORT static bool HasLiveWebContentsForBrowserContext(BrowserContext* browser_context);' content/public/browser/web_contents.h
sed -i '/^WebContentsImpl::WebContentsImpl(BrowserContext\* browser_context)/i\ bool WebContents::HasLiveWebContentsForBrowserContext(BrowserContext* browser_context) { for (WebContentsImpl* web_contents : WebContentsImpl::GetAllWebContents()) { if (web_contents->GetBrowserContext() == browser_context) { return true; } } return false; }' content/browser/web_contents/web_contents_impl.cc
sed -i '/#include "content\/public\/browser\/render_process_host.h"/a#include "content/public/browser/web_contents.h"' chrome/browser/profiles/profile_destroyer.cc
sed -i '/^void ProfileDestroyer::DestroyOTRProfileWhenAppropriateWithTimeout($/,/MaybeSendDestroyedNotification/{/  profile->MaybeSendDestroyedNotification();/i\
if (content::WebContents::HasLiveWebContentsForBrowserContext(profile)) { return; }
}' chrome/browser/profiles/profile_destroyer.cc

# ===== COMPREHENSIVE UI TOGGLE SYSTEM =====
# All toggles read from SharedPreferences with "ui_hide_*" / "ui_disable_*" keys
# and are controlled via Settings -> Appearance

PREFS='org.chromium.base.ContextUtils.getAppSharedPreferences()'
DELEGATE='chrome/android/java/src/org/chromium/chrome/browser/tabbed_mode/TabbedAppMenuPropertiesDelegate.java'

# --- MAIN MENU: Tab Groups ---
sed -i "s|mTabGroupItemBuilder.shouldShowTabGroupsParentItem(currentTab)|(!${PREFS}.getBoolean(\"ui_hide_menu_tab_groups\", true) \&\& mTabGroupItemBuilder.shouldShowTabGroupsParentItem(currentTab))|" "$DELEGATE"
sed -i "s|mTabGroupItemBuilder.shouldShowAddToGroup(currentTab)|(!${PREFS}.getBoolean(\"ui_hide_menu_tab_groups\", true) \&\& mTabGroupItemBuilder.shouldShowAddToGroup(currentTab))|" "$DELEGATE"
sed -i "s|modelList.add(mTabGroupItemBuilder.buildNewTabGroupItemWithoutTab());|if (!${PREFS}.getBoolean(\"ui_hide_menu_tab_groups\", true)) { modelList.add(mTabGroupItemBuilder.buildNewTabGroupItemWithoutTab()); }|" "$DELEGATE"

# --- MAIN MENU: Manage Windows ---
sed -i "s|if (MultiWindowUtils.shouldShowManageWindowsMenu())|if (!${PREFS}.getBoolean(\"ui_hide_menu_manage_windows\", true) \&\& MultiWindowUtils.shouldShowManageWindowsMenu())|g" "$DELEGATE"

# --- MAIN MENU: Quick Delete ---
sed -i "s|return !isIncognitoShowing();|return !${PREFS}.getBoolean(\"ui_hide_menu_quick_delete\", true) \&\& !isIncognitoShowing();|" "$DELEGATE"

# --- MAIN MENU: Passwords & Autofill ---
sed -i "s|modelList.add(buildPasswordsAndAutofillParentItem());|if (!${PREFS}.getBoolean(\"ui_hide_menu_passwords\", true)) { modelList.add(buildPasswordsAndAutofillParentItem()); }|" "$DELEGATE"

# --- ICON ROW: conditional Forward button ---
sed -i "s|iconModels\.add(buildForwardActionModel(currentTab));|if (currentTab != null \&\& currentTab.canGoForward()) { iconModels.add(buildForwardActionModel(currentTab)); }|" "$DELEGATE"

# --- MAIN MENU: New Incognito Tab ---
sed -i "s|modelList.add(buildNewIncognitoTabItem());|if (!${PREFS}.getBoolean(\"ui_hide_menu_new_incognito_tab\", false)) { modelList.add(buildNewIncognitoTabItem()); }|g" "$DELEGATE"

# --- MAIN MENU: Bookmarks ---
sed -i "s|modelList.add(mBookmarksItemBuilder.buildBookmarksItem(|if (!${PREFS}.getBoolean(\"ui_hide_menu_bookmarks\", false)) { modelList.add(mBookmarksItemBuilder.buildBookmarksItem(|" "$DELEGATE"
sed -i "s|modelList.add(mBookmarksItemBuilder.buildBookmarksParentItem(|if (!${PREFS}.getBoolean(\"ui_hide_menu_bookmarks\", false)) { modelList.add(mBookmarksItemBuilder.buildBookmarksParentItem(|" "$DELEGATE"
# close the if-braces for bookmarks (the line ends with ));  need to add } )
sed -i '/buildBookmarksItem(shouldShowIconBeforeItem));$/ s|));|)); }|' "$DELEGATE"
sed -i '/buildBookmarksParentItem(currentTab));$/ s|));|)); }|' "$DELEGATE"

# --- MAIN MENU: History ---
sed -i "s|modelList.add(mHistoryItemBuilder.buildHistoryItem(|if (!${PREFS}.getBoolean(\"ui_hide_menu_history\", false)) { modelList.add(mHistoryItemBuilder.buildHistoryItem(|" "$DELEGATE"
sed -i '/buildHistoryItem(shouldShowIconBeforeItem));$/ s|));|)); }|' "$DELEGATE"
sed -i "s|modelList.add(mHistoryItemBuilder.buildHistoryParentItem());|if (!${PREFS}.getBoolean(\"ui_hide_menu_history\", false)) { modelList.add(mHistoryItemBuilder.buildHistoryParentItem()); }|" "$DELEGATE"

# --- MAIN MENU: Recent Tabs ---
sed -i "s|modelList.add(mHistoryItemBuilder.buildRecentTabsItem(|if (!${PREFS}.getBoolean(\"ui_hide_menu_recent_tabs\", false)) { modelList.add(mHistoryItemBuilder.buildRecentTabsItem(|" "$DELEGATE"
sed -i '/buildRecentTabsItem(shouldShowIconBeforeItem));$/ s|));|)); }|' "$DELEGATE"

# --- MAIN MENU: Downloads ---
sed -i "s|modelList.add(buildDownloadsItem());|if (!${PREFS}.getBoolean(\"ui_hide_menu_downloads\", false)) { modelList.add(buildDownloadsItem()); }|g" "$DELEGATE"

# --- MAIN MENU: Share ---
sed -i "s|modelList.add(buildShareListItem(|if (!${PREFS}.getBoolean(\"ui_hide_menu_share\", false)) { modelList.add(buildShareListItem(|" "$DELEGATE"
sed -i '/buildShareListItem(shouldShowIconBeforeItem));$/ s|));|)); }|' "$DELEGATE"

# --- MAIN MENU: Find in Page ---
sed -i "s|if (shouldShowFindInPageItem(currentTab)) modelList.add(buildFindInPageItem(currentTab));|if (!${PREFS}.getBoolean(\"ui_hide_menu_find_in_page\", false) \&\& shouldShowFindInPageItem(currentTab)) modelList.add(buildFindInPageItem(currentTab));|g" "$DELEGATE"

# --- MAIN MENU: Translate ---
sed -i "s|if (shouldShowTranslateMenuItem(currentTab)) {|if (!${PREFS}.getBoolean(\"ui_hide_menu_translate\", false) \&\& shouldShowTranslateMenuItem(currentTab)) {|g" "$DELEGATE"

# --- MAIN MENU: Page Zoom ---
sed -i "s|if (shouldShowPageZoomItem(currentTab)|if (!${PREFS}.getBoolean(\"ui_hide_menu_page_zoom\", false) \&\& shouldShowPageZoomItem(currentTab)|g" "$DELEGATE"

# --- MAIN MENU: Download Page ---
sed -i "s|if (shouldShowDownloadPageMenuItem(currentTab))|if (!${PREFS}.getBoolean(\"ui_hide_menu_download_page\", false) \&\& shouldShowDownloadPageMenuItem(currentTab))|g" "$DELEGATE"

# --- MAIN MENU: Print ---
sed -i "s|if (shouldShowPrintItem(currentTab))|if (!${PREFS}.getBoolean(\"ui_hide_menu_print\", false) \&\& shouldShowPrintItem(currentTab))|g" "$DELEGATE"

# --- MAIN MENU: Add to Home Screen / Install App ---
sed -i "s|if (shouldShowHomeScreenMenuItem(|if (!${PREFS}.getBoolean(\"ui_hide_menu_add_to_homescreen\", false) \&\& shouldShowHomeScreenMenuItem(|" "$DELEGATE"

# --- MAIN MENU: Request Desktop Site ---
sed -i "s|if (rdsListItem != null) modelList.add(rdsListItem);|if (!${PREFS}.getBoolean(\"ui_hide_menu_desktop_site\", false) \&\& rdsListItem != null) modelList.add(rdsListItem);|g" "$DELEGATE"

# --- MAIN MENU: Auto Dark ---
sed -i "s|if (shouldShowAutoDarkItem(currentTab, isNativePage))|if (!${PREFS}.getBoolean(\"ui_hide_menu_auto_dark\", false) \&\& shouldShowAutoDarkItem(currentTab, isNativePage))|g" "$DELEGATE"

# --- MAIN MENU: Read Aloud ---
sed -i 's|protected void observeAndMaybeAddReadAloud(ModelList modelList, @Nullable Tab currentTab) {|& if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_hide_menu_read_aloud", false)) return;|' "$DELEGATE"
sed -i 's|protected void observeAndMaybeAddReadAloud(ModelList modelList, @Nullable Tab currentTab) {|& if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_hide_menu_read_aloud", false)) return;|' chrome/android/java/src/org/chromium/chrome/browser/app/appmenu/AppMenuPropertiesDelegateImpl.java

# --- MAIN MENU: Reader Mode ---
sed -i "s|if (mMoreToolsItemBuilder.shouldShowReaderModeItem(currentTab))|if (!${PREFS}.getBoolean(\"ui_hide_menu_reader_mode\", false) \&\& mMoreToolsItemBuilder.shouldShowReaderModeItem(currentTab))|g" "$DELEGATE"

# --- MAIN MENU: Extensions ---
sed -i "s|if (shouldShowExtensionsItem())|if (!${PREFS}.getBoolean(\"ui_hide_menu_extensions\", false) \&\& shouldShowExtensionsItem())|g" "$DELEGATE"

# --- MAIN MENU: Lens Overlay ---
sed -i "s|if (shouldShowLensOverlayItem(currentTab)) modelList.add(buildLensOverlayItem(currentTab));|if (!${PREFS}.getBoolean(\"ui_hide_menu_lens_overlay\", false) \&\& shouldShowLensOverlayItem(currentTab)) modelList.add(buildLensOverlayItem(currentTab));|g" "$DELEGATE"

# --- MAIN MENU: Price Tracking ---
sed -i "s|if (priceTrackingItem != null) modelList.add(priceTrackingItem);|if (!${PREFS}.getBoolean(\"ui_hide_menu_price_tracking\", false) \&\& priceTrackingItem != null) modelList.add(priceTrackingItem);|g" "$DELEGATE"

# --- MAIN MENU: NTP Customizations ---
sed -i "s|if (mMoreToolsItemBuilder.shouldShowNtpCustomizations(currentTab))|if (!${PREFS}.getBoolean(\"ui_hide_menu_ntp_customizations\", false) \&\& mMoreToolsItemBuilder.shouldShowNtpCustomizations(currentTab))|g" "$DELEGATE"

# --- MAIN MENU: Help ---
sed -i "s|modelList.add(buildHelpItem());|if (!${PREFS}.getBoolean(\"ui_hide_menu_help\", false)) { modelList.add(buildHelpItem()); }|g" "$DELEGATE"
sed -i "s|modelList.add(buildHelpParentItem());|if (!${PREFS}.getBoolean(\"ui_hide_menu_help\", false)) { modelList.add(buildHelpParentItem()); }|g" "$DELEGATE"

# --- MAIN MENU: Managed By ---
sed -i "s|if (shouldShowManagedByMenuItem(currentTab))|if (!${PREFS}.getBoolean(\"ui_hide_menu_managed_by\", false) \&\& shouldShowManagedByMenuItem(currentTab))|g" "$DELEGATE"

# --- MAIN MENU: Open With / Open in App ---
sed -i "s|if (shouldShowOpenWithItem(currentTab))|if (!${PREFS}.getBoolean(\"ui_hide_menu_open_with\", false) \&\& shouldShowOpenWithItem(currentTab))|g" "$DELEGATE"
sed -i "s|if (shouldShowOpenInAppItem())|if (!${PREFS}.getBoolean(\"ui_hide_menu_open_with\", false) \&\& shouldShowOpenInAppItem())|g" "$DELEGATE"

# --- MAIN MENU: Glic ---
sed -i "s|if (openGlicItem != null) modelList.add(openGlicItem);|if (!${PREFS}.getBoolean(\"ui_hide_menu_glic\", false) \&\& openGlicItem != null) modelList.add(openGlicItem);|g" "$DELEGATE"

# --- MAIN MENU: TTC ---
sed -i "s|if (ttcItem != null) modelList.add(ttcItem);|if (!${PREFS}.getBoolean(\"ui_hide_menu_ttc\", false) \&\& ttcItem != null) modelList.add(ttcItem);|g" "$DELEGATE"

# --- MAIN MENU: More Tools ---
sed -i "s|if (mMoreToolsItemBuilder.shouldShowMoreToolsItem(currentTab))|if (!${PREFS}.getBoolean(\"ui_hide_menu_more_tools\", false) \&\& mMoreToolsItemBuilder.shouldShowMoreToolsItem(currentTab))|g" "$DELEGATE"

# --- MAIN MENU: Save & Share ---
sed -i "s|if (shouldShowSaveAndShareItem(|if (!${PREFS}.getBoolean(\"ui_hide_menu_save_share\", false) \&\& shouldShowSaveAndShareItem(|" "$DELEGATE"

# --- MAIN MENU: Paint Preview ---
sed -i "s|if (mSaveAndShareItemBuilder.shouldShowPaintPreview(|if (!${PREFS}.getBoolean(\"ui_hide_menu_save_share\", false) \&\& mSaveAndShareItemBuilder.shouldShowPaintPreview(|" "$DELEGATE"

# --- MAIN MENU: Image Descriptions ---
sed -i "s|if (shouldShowGetImageDescriptionsItem(currentTab))|if (!${PREFS}.getBoolean(\"ui_hide_menu_image_descriptions\", false) \&\& shouldShowGetImageDescriptionsItem(currentTab))|g" "$DELEGATE"

# --- MAIN MENU: Listen to Feed ---
sed -i "s|if (shouldShowListenToFeedItem(currentTab))|if (!${PREFS}.getBoolean(\"ui_hide_menu_listen_feed\", false) \&\& shouldShowListenToFeedItem(currentTab))|g" "$DELEGATE"

# --- MAIN MENU: Content Filter Help ---
sed -i "s|if (shouldShowContentFilterHelpCenterMenuItem())|if (!${PREFS}.getBoolean(\"ui_hide_menu_content_filter\", false) \&\& shouldShowContentFilterHelpCenterMenuItem())|g" "$DELEGATE"

# --- MAIN MENU: Homepage ---
sed -i "s|HomepageManager.getInstance().shouldShowHomepageMenuItem()|(!${PREFS}.getBoolean(\"ui_hide_menu_homepage\", false) \&\& HomepageManager.getInstance().shouldShowHomepageMenuItem())|g" "$DELEGATE"

# --- MAIN MENU: New Window / Move to Other Window / New Incognito Window ---
sed -i "s|if (shouldShowNewWindow())|if (!${PREFS}.getBoolean(\"ui_hide_menu_new_window\", false) \&\& shouldShowNewWindow())|g" "$DELEGATE"
sed -i "s|if (shouldShowNewIncognitoWindow())|if (!${PREFS}.getBoolean(\"ui_hide_menu_new_incognito_window\", false) \&\& shouldShowNewIncognitoWindow())|g" "$DELEGATE"
sed -i "s|if (shouldShowMoveToOtherWindow())|if (!${PREFS}.getBoolean(\"ui_hide_menu_move_to_window\", false) \&\& shouldShowMoveToOtherWindow())|g" "$DELEGATE"

# --- OVERVIEW MENU: Close All Tabs ---
sed -i "s|modelList.add(buildCloseAllTabsItem());|if (!${PREFS}.getBoolean(\"ui_hide_menu_close_all_tabs\", false)) { modelList.add(buildCloseAllTabsItem()); }|" "$DELEGATE"

# --- OVERVIEW MENU: Select Tabs ---
sed -i "s|if (shouldShowSelectTabsItem()) modelList.add(buildSelectTabsItem());|if (!${PREFS}.getBoolean(\"ui_hide_menu_select_tabs\", false) \&\& shouldShowSelectTabsItem()) modelList.add(buildSelectTabsItem());|" "$DELEGATE"

# --- MAIN MENU: Update Item ---
sed -i "s|if (mUpdateMenuItemVisible) {|if (!${PREFS}.getBoolean(\"ui_hide_menu_update\", false) \&\& mUpdateMenuItemVisible) {|" "$DELEGATE"

# tab group bottom bar: remove group dialog arrow button, fading edge overlays, and support dynamic hiding via preferences
sed -i 's|mShowGroupDialogButton.setVisibility(visible ? View.VISIBLE : View.GONE);|mShowGroupDialogButton.setVisibility(View.GONE);|' chrome/android/features/tab_ui/java/src/org/chromium/chrome/browser/tasks/tab_management/TabGroupUiToolbarView.java
sed -i 's|mShowGroupDialogButton = findViewById(R.id.toolbar_show_group_dialog_button);|& mShowGroupDialogButton.setVisibility(View.GONE);|' chrome/android/features/tab_ui/java/src/org/chromium/chrome/browser/tasks/tab_management/TabGroupUiToolbarView.java
sed -i 's|id/toolbar_show_group_dialog_button"|& android:visibility="gone"|' chrome/android/features/tab_ui/java/res/layout/bottom_tab_strip_toolbar.xml
sed -i 's|id/toolbar_show_group_dialog_button"|& android:visibility="gone"|' chrome/android/features/tab_ui/java/res/layout/dynamic_bottom_tab_strip_toolbar.xml
sed -i 's|android:layout_width="@dimen/tab_strip_fading_edge_width"|android:layout_width="0dp" android:visibility="gone"|g' chrome/android/features/tab_ui/java/res/layout/bottom_tab_strip_toolbar.xml
sed -i 's|android:layout_width="@dimen/tab_strip_fading_edge_width"|android:layout_width="0dp" android:visibility="gone"|g' chrome/android/features/tab_ui/java/res/layout/dynamic_bottom_tab_strip_toolbar.xml
sed -i 's|mFadingEdgeStart = findViewById(R.id.tab_strip_fading_edge_start);|& mFadingEdgeStart.setVisibility(View.GONE);|' chrome/android/features/tab_ui/java/src/org/chromium/chrome/browser/tasks/tab_management/TabGroupUiToolbarView.java
sed -i 's|mFadingEdgeEnd = findViewById(R.id.tab_strip_fading_edge_end);|& mFadingEdgeEnd.setVisibility(View.GONE);|' chrome/android/features/tab_ui/java/src/org/chromium/chrome/browser/tasks/tab_management/TabGroupUiToolbarView.java
sed -i 's|super.onFinishInflate();|& if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_hide_bottom_tab_strip", false)) { setVisibility(View.GONE); } if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_hide_new_tab_button", false) \&\& mNewTabButton != null) { mNewTabButton.setVisibility(View.GONE); }|' chrome/android/features/tab_ui/java/src/org/chromium/chrome/browser/tasks/tab_management/TabGroupUiToolbarView.java

# toolbar and omnibox: support dynamic hiding of home, voice, and lens buttons
sed -i 's|super.setVisibility(mHasSpaceToShow ? mVisibility : GONE);|if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_hide_home_button", false)) { super.setVisibility(GONE); return; } &|' chrome/browser/ui/android/toolbar/java/src/org/chromium/chrome/browser/toolbar/home_button/HomeButton.java
sed -i 's|private void setLensButtonVisibility(boolean shouldShowLensButton) {|& if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_hide_lens_button", false)) shouldShowLensButton = false;|' chrome/browser/ui/android/omnibox/java/src/org/chromium/chrome/browser/omnibox/LocationBarMediator.java
sed -i 's|public boolean isVoiceSearchEnabled() {|& if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_hide_voice_search", false)) return false;|' chrome/browser/ui/android/omnibox/java/src/org/chromium/chrome/browser/omnibox/voice/VoiceRecognitionHandler.java

# promos: disable default browser promos if toggled
sed -i 's|static boolean isFeatureEnabled() {|& if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_disable_default_browser_promo", true)) return false;|' chrome/browser/ui/android/default_browser_promo/java/src/org/chromium/chrome/browser/ui/default_browser_promo/DefaultBrowserPromoUtils.java
sed -i 's|public boolean shouldShowNonRoleManagerPromo(Context context) {|& if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_disable_default_browser_promo", true)) return false;|' chrome/browser/ui/android/default_browser_promo/java/src/org/chromium/chrome/browser/ui/default_browser_promo/DefaultBrowserPromoUtils.java
sed -i 's|public boolean shouldShowAppMenuItemEntryPoint() {|& if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_disable_default_browser_promo", true)) return false;|' chrome/browser/ui/android/default_browser_promo/java/src/org/chromium/chrome/browser/ui/default_browser_promo/DefaultBrowserPromoUtils.java

# ui customization preferences: comprehensive categories and toggles in Settings -> Appearance (appearance_preferences.xml)
cat > /tmp/titanium_prefs_patch.xml << 'PREFS_EOF'
    <PreferenceCategory android:title="Нижняя панель и вкладки" android:order="10">
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_bottom_tab_strip" android:title="Скрыть нижнюю панель вкладок" android:summary="Полностью убирает полосу открытых вкладок снизу" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_new_tab_button" android:title="Скрыть кнопку новой вкладки (+)" android:summary="Убирает кнопку добавления новой вкладки на нижней панели" android:defaultValue="false" />
    </PreferenceCategory>
    <PreferenceCategory android:title="Меню: Основное" android:order="11">
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_tab_groups" android:title="Скрыть группы вкладок" android:summary="Убирает все пункты групп вкладок" android:defaultValue="true" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_new_incognito_tab" android:title="Скрыть Новая вкладка Инкогнито" android:summary="Убирает пункт открытия инкогнито-вкладки" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_manage_windows" android:title="Скрыть Управление окнами" android:summary="Убирает пункт управления окнами" android:defaultValue="true" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_new_window" android:title="Скрыть Новое окно" android:summary="Убирает пункт открытия нового окна" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_new_incognito_window" android:title="Скрыть Новое окно Инкогнито" android:summary="Убирает пункт открытия инкогнито-окна" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_move_to_window" android:title="Скрыть Переместить в другое окно" android:summary="Убирает пункт перемещения вкладки" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_passwords" android:title="Скрыть Пароли и автозаполнение" android:summary="Убирает пункт паролей из меню" android:defaultValue="true" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_quick_delete" android:title="Скрыть Быстрое удаление" android:summary="Убирает пункт быстрого удаления данных" android:defaultValue="true" />
    </PreferenceCategory>
    <PreferenceCategory android:title="Меню: Навигация" android:order="12">
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_bookmarks" android:title="Скрыть Закладки" android:summary="Убирает пункт закладок из меню" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_history" android:title="Скрыть Историю" android:summary="Убирает пункт истории просмотров" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_recent_tabs" android:title="Скрыть Недавние вкладки" android:summary="Убирает пункт недавних вкладок" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_downloads" android:title="Скрыть Загрузки" android:summary="Убирает пункт загрузок из меню" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_homepage" android:title="Скрыть Домашнюю страницу" android:summary="Убирает пункт перехода на домашнюю страницу" android:defaultValue="false" />
    </PreferenceCategory>
    <PreferenceCategory android:title="Меню: Контент страницы" android:order="13">
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_share" android:title="Скрыть Поделиться" android:summary="Убирает пункт Поделиться из меню" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_find_in_page" android:title="Скрыть Найти на странице" android:summary="Убирает поиск по тексту страницы" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_translate" android:title="Скрыть Перевод" android:summary="Убирает пункт перевода страницы" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_page_zoom" android:title="Скрыть Масштаб страницы" android:summary="Убирает управление масштабом" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_desktop_site" android:title="Скрыть Версия для ПК" android:summary="Убирает переключатель десктопной версии" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_auto_dark" android:title="Скрыть Авто-тёмная тема" android:summary="Убирает переключатель тёмного режима страниц" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_read_aloud" android:title="Скрыть Озвучивание" android:summary="Убирает озвучивание текста страницы" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_reader_mode" android:title="Скрыть Режим чтения" android:summary="Убирает пункт упрощённого режима" android:defaultValue="false" />
    </PreferenceCategory>
    <PreferenceCategory android:title="Меню: Инструменты" android:order="14">
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_download_page" android:title="Скрыть Скачать страницу" android:summary="Убирает пункт скачивания страницы" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_print" android:title="Скрыть Печать" android:summary="Убирает пункт печати" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_add_to_homescreen" android:title="Скрыть На главный экран" android:summary="Убирает добавление сайта на рабочий стол" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_extensions" android:title="Скрыть Расширения" android:summary="Убирает пункт расширений из меню" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_more_tools" android:title="Скрыть Ещё инструменты" android:summary="Убирает подменю Ещё инструменты" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_save_share" android:title="Скрыть Сохранить и поделиться" android:summary="Убирает подменю сохранения и публикации" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_open_with" android:title="Скрыть Открыть в приложении" android:summary="Убирает Открыть с.../В приложении" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_lens_overlay" android:title="Скрыть Lens Overlay" android:summary="Убирает пункт сканера контента Lens" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_price_tracking" android:title="Скрыть Отслеживание цен" android:summary="Убирает отслеживание цен на товары" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_image_descriptions" android:title="Скрыть Описания изображений" android:summary="Убирает получение описаний для картинок" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_listen_feed" android:title="Скрыть Прослушать ленту" android:summary="Убирает озвучивание ленты новостей" android:defaultValue="false" />
    </PreferenceCategory>
    <PreferenceCategory android:title="Меню: Системное" android:order="15">
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_help" android:title="Скрыть Справку" android:summary="Убирает пункт Справка и отзыв" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_update" android:title="Скрыть Обновление" android:summary="Убирает баннер обновления из меню" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_managed_by" android:title="Скрыть Управляется организацией" android:summary="Убирает корпоративную метку" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_content_filter" android:title="Скрыть Фильтр контента" android:summary="Убирает ссылку на центр помощи по фильтрации" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_ntp_customizations" android:title="Скрыть Настройки NTP" android:summary="Убирает настройки новой вкладки из меню" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_glic" android:title="Скрыть Glic (AI)" android:summary="Убирает пункт AI-ассистента Glic" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_ttc" android:title="Скрыть TTC" android:summary="Убирает сессии Tab-to-Cloud" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_close_all_tabs" android:title="Скрыть Закрыть все вкладки" android:summary="Убирает из обзорного меню" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_menu_select_tabs" android:title="Скрыть Выбрать вкладки" android:summary="Убирает из обзорного меню" android:defaultValue="false" />
    </PreferenceCategory>
    <PreferenceCategory android:title="Адресная строка и тулбар" android:order="16">
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_home_button" android:title="Скрыть кнопку Домой" android:summary="Убирает значок домика на верхней панели" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_voice_search" android:title="Скрыть значок микрофона" android:summary="Убирает голосовой ввод из адресной строки" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_hide_lens_button" android:title="Скрыть значок камеры (Lens)" android:summary="Убирает сканер QR и поиск по камере" android:defaultValue="false" />
    </PreferenceCategory>
    <PreferenceCategory android:title="Уведомления и промо" android:order="17">
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_disable_default_browser_promo" android:title="Скрыть промо Браузер по умолчанию" android:summary="Блокирует всплывающие предложения сделать браузер основным" android:defaultValue="true" />
    </PreferenceCategory>
    <PreferenceCategory android:title="Новая вкладка (NTP)" android:order="18">
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_disable_discover_feed" android:title="Скрыть ленту Discover" android:summary="Отключает ленту новостей на новой вкладке" android:defaultValue="false" />
        <org.chromium.components.browser_ui.settings.ChromeSwitchPreference android:key="ui_disable_magic_stack" android:title="Скрыть модули Magic Stack" android:summary="Отключает карточки подсказок на новой вкладке" android:defaultValue="false" />
    </PreferenceCategory>
PREFS_EOF

# inject the preferences XML block inside <PreferenceScreen> (before </PreferenceScreen>)
python3 -c '
xml_file = "chrome/android/java/res/xml/appearance_preferences.xml"
with open(xml_file, "r") as f:
    xml = f.read()
with open("/tmp/titanium_prefs_patch.xml", "r") as f:
    patch = f.read()
if "</PreferenceScreen>" in xml and "ui_hide_bottom_tab_strip" not in xml:
    xml = xml.replace("</PreferenceScreen>", patch + "\n</PreferenceScreen>")
    with open(xml_file, "w") as f:
        f.write(xml)
'

# tab search: remove "Search tabs" search bar from tab switcher
sed -i 's|newFlag(ChromeFeatureList.ANDROID_HUB_SEARCH, true);|newFlag(ChromeFeatureList.ANDROID_HUB_SEARCH, false);|' chrome/browser/flags/android/java/src/org/chromium/chrome/browser/flags/ChromeFeatureList.java
sed -i 's|newFlag(ChromeFeatureList.TAB_SWITCHER_SEARCH, true);|newFlag(ChromeFeatureList.TAB_SWITCHER_SEARCH, false);|' chrome/browser/flags/android/java/src/org/chromium/chrome/browser/flags/ChromeFeatureList.java
find chrome/android/features/tab_ui/java/res/layout -type f \( -name "*hub_search*.xml" -o -name "*search_box*.xml" \) -exec sed -i 's|<LinearLayout|<LinearLayout android:visibility="gone"|; s|<FrameLayout|<FrameLayout android:visibility="gone"|' {} +

# tab group colors: remove tab group color feature and color indicators
sed -i 's|newFlag(ChromeFeatureList.TAB_GROUP_PARITY_ANDROID, true);|newFlag(ChromeFeatureList.TAB_GROUP_PARITY_ANDROID, false);|' chrome/browser/flags/android/java/src/org/chromium/chrome/browser/flags/ChromeFeatureList.java
find chrome/android/features/tab_ui/java/res/layout -type f -name "*tab_grid*.xml" -exec sed -i 's|id/tab_group_color_icon"|& android:visibility="gone"|' {} +

# NTP: disable Discover Feed if toggled
sed -i 's|public static boolean isFeedEnabled(Profile profile) {|& if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_disable_discover_feed", false)) return false;|' chrome/browser/feed/android/java/src/org/chromium/chrome/browser/feed/FeedFeatures.java

# NTP: disable Magic Stack modules if toggled
sed -i 's|return mSharedPreferencesManager.readBoolean(getSettingsPreferenceKey(moduleType),|if (org.chromium.base.ContextUtils.getAppSharedPreferences().getBoolean("ui_disable_magic_stack", false)) return false; &|' chrome/browser/magic_stack/android/java/src/org/chromium/chrome/browser/magic_stack/HomeModulesConfigManager.java

export PATCHED=1
