{ lib, user, ... }:
{
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.${user}.openssh.authorizedKeys.keys = [
    # ~/.ssh/id_ed25519.pub
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8koEKvE/Pgc6QyhDbCFKMwMvWPyLYKWlyl84q6qmXC langj@moonshield"
    # ~/.ssh/id_rsa.pub
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCszYA+pQGpK6zhV/Xhqgc4BJlZieDTVF+RmQxp3q/SqgIUFhaNNID+/0DqPshcF4xGz4eaTl0BFu363ERsWeJHpU2fDMztYt0w3Q9FXbQqDaLMj2tcQAXMH0tG1SZOkzs1MbfrV1EMuc/EkKHl+O8iflb+xnN9BB7HrDp18ZEH9soZzgTTpqTBJ2Jy9GbJYjKlc7X6IOOcJ9C14f81qHPNBAYhms4xZws5gV5RLMbj480ubp58oRKq1qA5jv4qbmBM57+dSg99PiPtp51GAHK1hXN+pCWsIcQbbEykrFP5VX5t70RH1S2J4OIDy+fR0gbgL3QurcnZ0zLRYjaa6LiIWBqggOPKRhDHw4ak1vru2dIgBAvlkPPoHupYi2W8jpApJ8OnWH7HB6WFRvC6VM/yfi+7aIr9pmoUeSLAoPDZzNxzrR+O6lKbNkGKG/6kUtSBoDmRewDqAB5m8F1rbWiOc0/yo3o8HQ80Ma4sMlFolswLvhk54IncGI6pN83fxd6PFNljVTY/bilvbGyDCqEwJPpaez+weO3y5jONMrYMpLAt/PYt1v9w47hvNfq4mL62gbVNQVhT1OvgZKZZAZEGkJLLeno5kf1F4r9mly8IpZEWzKjsxQWMQ7CivxTm5Yf1QKiFGCM8i3aecyHjZdJ+yWlY8jydeBTSQTvQCMVVAw== langj@xps"
  ];
}
