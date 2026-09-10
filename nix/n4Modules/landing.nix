{
  pkgs,
  http,
  lib,
  ...
}:
{
  routes = [
    {
      reply.body = builtins.readFile ./static/index.html;
    }
  ];

}
