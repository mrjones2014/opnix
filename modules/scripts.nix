{ config, lib, pkgs, ... }:
let
  cfg = config.opnix;
  op = cfg.opBin;
  mountCommand = ''
    grep -q "${cfg.secretsMountPoint} ramfs" /proc/mounts ||
      mount -t ramfs none "${cfg.secretsMountPoint}" -o nodev,nosuid,mode=0751
  '';
  newGeneration = ''
    _opnix_generation="$(basename "$(readlink ${cfg.secretsDir})" || echo 0)"
    (( ++_opnix_generation ))
    echo "[opnix] creating new generation in ${cfg.secretsMountPoint}/$_opnix_generation"
    mkdir -p "${cfg.secretsMountPoint}"
    chmod 0751 "${cfg.secretsMountPoint}"
    ${mountCommand}
    mkdir -p "${cfg.secretsMountPoint}/$_opnix_generation"
    chmod 0751 "${cfg.secretsMountPoint}/$_opnix_generation"
  '';
  chownGroup = "keys";
  # chown the secrets mountpoint and the current generation to the keys group
  # instead of leaving it root:root.
  chownMountPoint = ''
    chown :${chownGroup} "${cfg.secretsMountPoint}" "${cfg.secretsMountPoint}/$_opnix_generation"
  '';
  cleanupAndLink = ''
    echo "[opnix] symlinking new secrets to ${cfg.secretsDir} (generation $_opnix_generation)..."
    ln -sfT "${cfg.secretsMountPoint}/$_opnix_generation" ${cfg.secretsDir}

    (( _opnix_generation > 1 )) && {
    echo "[opnix] removing old secrets (generation $(( _opnix_generation - 1 )))..."
    rm -rf "${cfg.secretsMountPoint}/$(( _opnix_generation - 1 ))"
    }
  '';
  setTruePath = secretType: ''
    ${if secretType.symlink then ''
      _truePath="${cfg.secretsMountPoint}/$_opnix_generation/${secretType.name}"
    '' else ''
      _truePath="${secretType.path}"
    ''}
  '';
  chownSecret = secretType: ''
    ${setTruePath secretType}
    chown ${secretType.user}:${secretType.group} "$_truePath"
  '';
  chownSecrets = builtins.concatStringsSep "\n"
    ([ "echo '[opnix] chowning...'" ] ++ [ chownMountPoint ]
      ++ (map chownSecret (builtins.attrValues cfg.secrets)));
  # TODO
  installSecret = secretType: ''
    ${setTruePath secretType}
    echo "expanding '${secretType.name}' to '$_truePath'..."
    TMP_FILE="$_truePath.tmp"

    mkdir -p "$(dirname "$_truePath")"
    [ "${secretType.path}" != "${cfg.secretsDir}/${secretType.name}" ] && mkdir -p "$(dirname "${secretType.path}")"
    (
      umask u=r,g=,o=
      test -d "$(dirname "$TMP_FILE")" || echo "[opnix] WARNING: $(dirname "$TMP_FILE") does not exist!"
      set -x
      OP_SERVICE_ACCOUNT_TOKEN=$(cat ${cfg.serviceAccountTokenPath}) ${op} inject -o "$TMP_FILE" -i ${pkgs.writeText "blah" secretType.source} --config /root/.config/op
    )
    chmod ${secretType.mode} "$TMP_FILE"
    mv -f "$TMP_FILE" "$_truePath"

    ${lib.optionalString secretType.symlink ''
      [ "${secretType.path}" != "${cfg.secretsDir}/${secretType.name}" ] && ln -sfT "${cfg.secretsDir}/${secretType.name}" "${secretType.path}"
    ''}
  '';
  testServiceAccountToken = ''
    if [ ! -f "${cfg.serviceAccountTokenPath}" ]; then
      echo "[opnix] ERROR: file '${cfg.serviceAccountTokenPath}' does not exist!"
      exit 1
    fi

    SA_TOKEN_FILE_PERMS=$(stat -c %a '${cfg.serviceAccountTokenPath}')
    if [ "$SA_TOKEN_FILE_PERMS" -ne "400" ] && [ "$SA_TOKEN_FILE_PERMS" -ne "600" ]; then
      echo "[opnix] WARN: file '${cfg.serviceAccountTokenPath}' has incorrect permissions: $SA_TOKEN_FILE_PERMS"
    fi

    _opnix_generation="$(basename "$(readlink ${cfg.secretsDir})" || echo 0)"
    (( ++_opnix_generation ))
  '';
  installSecrets = builtins.concatStringsSep "\n"
    ([
      "echo '[opnix] decrypting secrets...'"
      "mkdir -p /root/.config/op"
      "chmod 700 /root/.config/op"
      testServiceAccountToken
    ]
    ++ (map installSecret (builtins.attrValues cfg.secrets))
    ++ [ cleanupAndLink ]);
in
{
  inherit newGeneration;
  inherit installSecrets;
  inherit chownSecrets;
}
