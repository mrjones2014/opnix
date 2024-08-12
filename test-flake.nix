{
  opnix.secrets = {
    some-secret = {
      source = "{{ op://something/something/somethign }}";
      user = "SomeUser";
      group = "SomeGroup";
    };
  };
}
