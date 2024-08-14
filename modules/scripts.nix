{ config, lib, pkgs, ... }:
let
  cfg = config.opnix;
  op = cfg.opBin;
  op_tmp_dir = "/root/op_tmp";
  op_cfg_dir = "/root/.config/op";
  # fixes permissions issues with op session files
  createTmpDirShim = ''
    rm -rf ${op_tmp_dir}
    mkdir -p ${op_tmp_dir}
    chmod 600 ${op_tmp_dir}
  '';
  createOpConfigDir = ''
    mkdir -p ${op_cfg_dir}
    chmod 700 ${op_cfg_dir}
    if [ ! -f ${op_cfg_dir}/config ] || [ ! -s ${op_cfg_dir}/config ]; then
      echo "{}" > ${op_cfg_dir}/config
    fi
    chmod 600 ${op_cfg_dir}/config
  '';
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
  installSecret = secretType: ''
    ${setTruePath secretType}
    echo "expanding '${secretType.name}' to '$_truePath'..."
    TMP_FILE="$_truePath.tmp"

    mkdir -p "$(dirname "$_truePath")"
    # shellcheck disable=SC2050
    [ "${secretType.path}" != "${cfg.secretsDir}/${secretType.name}" ] && mkdir -p "$(dirname "${secretType.path}")"
    (
      umask u=r,g=,o=
      test -d "$(dirname "$TMP_FILE")" || echo "[opnix] WARNING: $(dirname "$TMP_FILE") does not exist!"
      # shellcheck disable=SC1091
      source "${cfg.environmentFile}"
      export OP_SERVICE_ACCOUNT_TOKEN
      set -x
      TMPDIR="${op_tmp_dir}" ${op} inject -o "$TMP_FILE" -i ${
        pkgs.writeText secretType.name secretType.source
      } --config ${op_cfg_dir}
    )
    chmod ${secretType.mode} "$TMP_FILE"
    mv -f "$TMP_FILE" "$_truePath"

    ${lib.optionalString secretType.symlink ''
      # shellcheck disable=SC2050
      [ "${secretType.path}" != "${cfg.secretsDir}/${secretType.name}" ] && ln -sfT "${cfg.secretsDir}/${secretType.name}" "${secretType.path}"
    ''}
  '';
  testServiceAccountToken = ''
    if [ ! -f "${cfg.environmentFile}" ]; then
      echo "[opnix] ERROR: environment file '${cfg.environmentFile}' does not exist!"
      exit 1
    fi

    if [ ! -s "${cfg.environmentFile}" ]; then
      echo "[opnix]: ERROR: environment file '${cfg.environmentFile}' is empty!"
      exit 1
    fi

    SA_TOKEN_FILE_PERMS=$(stat -c %a '${cfg.environmentFile}')
    if [ "$SA_TOKEN_FILE_PERMS" -ne "400" ] && [ "$SA_TOKEN_FILE_PERMS" -ne "600" ]; then
      echo "[opnix] WARN: environment file '${cfg.environmentFile}' has incorrect permissions: $SA_TOKEN_FILE_PERMS"
      echo "[opnix] WARN: environment file '${cfg.environmentFile}' should have permissions 400 or 600"
    fi

    _opnix_generation="$(basename "$(readlink ${cfg.secretsDir})" || echo 0)"
    (( ++_opnix_generation ))
  '';
  installSecrets = builtins.concatStringsSep "\n" ([
    "echo '[opnix] provisioning secrets...'"
    createOpConfigDir
    createTmpDirShim
    testServiceAccountToken
  ] ++ (map installSecret (builtins.attrValues cfg.secrets))
    ++ [ cleanupAndLink ]);
in {
  inherit createOpConfigDir;
  inherit newGeneration;
  inherit installSecrets;
  inherit chownSecrets;
}
