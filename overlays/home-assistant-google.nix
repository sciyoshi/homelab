_: prev: {
  home-assistant = prev.home-assistant.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # With report_state enabled, HA otherwise returns SUCCESS with the old
      # state before the service runs. Google Home then reverses its UI toggle.
      # Wait for device services, including cover movement/position commands,
      # while keeping background state reporting. The separate scene/script
      # nonblocking policy and the two-second EXECUTE deadline stay upstream.
      # https://github.com/home-assistant/core/issues/125793
      substituteInPlace homeassistant/components/google_assistant/trait.py \
        --replace-fail 'blocking=not self.config.should_report_state,' 'blocking=True,'
    '';
  });
}
