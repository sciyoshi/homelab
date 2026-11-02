_: prev: {
  home-assistant = prev.home-assistant.override (old: {
    packageOverrides =
      self: super:
      (old.packageOverrides or (_: _: { })) self super
      // {
        # pyjwt 2.14 rejects the non-url-safe base64 header this test fixture
        # uses, so yalexs 9.2.13 fails to build. Skip the fixture until yalexs
        # updates it.
        yalexs = super.yalexs.overridePythonAttrs (oldAttrs: {
          disabledTests = (oldAttrs.disabledTests or [ ]) ++ [
            "test_async_refresh_token"
          ];
        });
      };
  });
}
