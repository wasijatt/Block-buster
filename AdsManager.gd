extends Node

const USE_TEST_ADS := true
const ANDROID_TEST_BANNER_ID := "ca-app-pub-3940256099942544/6300978111"
const IOS_TEST_BANNER_ID := "ca-app-pub-3940256099942544/2934735716"
const ANDROID_TEST_INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
const IOS_TEST_INTERSTITIAL_ID := "ca-app-pub-3940256099942544/4411468910"
const ANDROID_PRODUCTION_BANNER_ID := "REPLACE_WITH_ANDROID_BANNER_ID"
const IOS_PRODUCTION_BANNER_ID := "REPLACE_WITH_IOS_BANNER_ID"
const ANDROID_PRODUCTION_INTERSTITIAL_ID := "REPLACE_WITH_ANDROID_INTERSTITIAL_ID"
const IOS_PRODUCTION_INTERSTITIAL_ID := "REPLACE_WITH_IOS_INTERSTITIAL_ID"
const MIN_INTERSTITIAL_INTERVAL_SECONDS := 120
const MIN_GAME_OVERS_BEFORE_INTERSTITIAL := 2

var banner_ad: AdView
var interstitial_ad: InterstitialAd
var interstitial_loader: InterstitialAdLoader
var ads_initialized := false
var consent_request_in_flight := false
var interstitial_load_in_flight := false
var banner_should_be_visible := true
var game_over_count := 0
var last_interstitial_shown_at := -MIN_INTERSTITIAL_INTERVAL_SECONDS

func _ready() -> void:
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		return
	_request_consent()

func _request_consent() -> void:
	if consent_request_in_flight:
		return
	consent_request_in_flight = true

	var request := ConsentRequestParameters.new()
	var consent_information := UserMessagingPlatform.consent_information
	consent_information.update(
		request,
		func() -> void:
			if consent_information.get_is_consent_form_available():
				UserMessagingPlatform.load_consent_form(
					func(form: ConsentForm) -> void:
						form.show(func(_error: FormError) -> void:
							_initialize_ads()
						)
				)
			else:
				_initialize_ads(),
		func(_error: FormError) -> void:
			_initialize_ads()
	)

func _initialize_ads() -> void:
	if ads_initialized:
		return
	ads_initialized = true

	var request_config := RequestConfiguration.new()
	request_config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	MobileAds.set_request_configuration(request_config)

	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_load_banner()
		_load_interstitial()
	MobileAds.initialize(listener)

func _load_banner() -> void:
	if banner_ad:
		banner_ad.destroy()
		banner_ad = null

	var ad_unit_id := _get_banner_id()
	if ad_unit_id.begins_with("REPLACE_WITH_"):
		push_warning("AdsManager: production banner ID is not configured")
		return

	var ad_size := AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	banner_ad = AdView.new(ad_unit_id, ad_size, AdPosition.BOTTOM)
	banner_ad.ad_listener.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		push_warning("AdsManager: banner failed to load: %s" % error.message)
	banner_ad.load_ad(AdRequest.new())
	if banner_should_be_visible:
		banner_ad.show()
	else:
		banner_ad.hide()

func _load_interstitial() -> void:
	if interstitial_ad or interstitial_load_in_flight:
		return

	var ad_unit_id := _get_interstitial_id()
	if ad_unit_id.begins_with("REPLACE_WITH_"):
		push_warning("AdsManager: production interstitial ID is not configured")
		return

	interstitial_loader = InterstitialAdLoader.new()
	interstitial_load_in_flight = true
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		interstitial_load_in_flight = false
		interstitial_ad = ad
		var full_screen_callback := FullScreenContentCallback.new()
		full_screen_callback.on_ad_dismissed_full_screen_content = _on_interstitial_finished
		full_screen_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
			_on_interstitial_finished()
		interstitial_ad.full_screen_content_callback = full_screen_callback
	callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		interstitial_load_in_flight = false
	interstitial_loader.load(ad_unit_id, AdRequest.new(), callback)

func show_interstitial_if_available() -> bool:
	if not interstitial_ad:
		return false
	if game_over_count < MIN_GAME_OVERS_BEFORE_INTERSTITIAL:
		return false
	var now_seconds := Time.get_ticks_msec() / 1000
	if now_seconds - last_interstitial_shown_at < MIN_INTERSTITIAL_INTERVAL_SECONDS:
		return false

	last_interstitial_shown_at = now_seconds
	interstitial_ad.show()
	return true

func consider_interstitial_after_game_over() -> void:
	game_over_count += 1
	show_interstitial_if_available()

func set_banner_visible(visible: bool) -> void:
	banner_should_be_visible = visible
	if not banner_ad:
		return
	if visible:
		banner_ad.show()
	else:
		banner_ad.hide()

func _on_interstitial_finished() -> void:
	if interstitial_ad:
		interstitial_ad.destroy()
		interstitial_ad = null
	_load_interstitial()

func _get_banner_id() -> String:
	if USE_TEST_ADS:
		return IOS_TEST_BANNER_ID if OS.get_name() == "iOS" else ANDROID_TEST_BANNER_ID
	return IOS_PRODUCTION_BANNER_ID if OS.get_name() == "iOS" else ANDROID_PRODUCTION_BANNER_ID

func _get_interstitial_id() -> String:
	if USE_TEST_ADS:
		return IOS_TEST_INTERSTITIAL_ID if OS.get_name() == "iOS" else ANDROID_TEST_INTERSTITIAL_ID
	return IOS_PRODUCTION_INTERSTITIAL_ID if OS.get_name() == "iOS" else ANDROID_PRODUCTION_INTERSTITIAL_ID

func _exit_tree() -> void:
	if banner_ad:
		banner_ad.destroy()
		banner_ad = null
	if interstitial_ad:
		interstitial_ad.destroy()
		interstitial_ad = null
