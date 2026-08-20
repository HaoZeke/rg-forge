from __future__ import annotations

import os
import subprocess
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "ci" / "gha" / "publish_packages.sh"


def run_publisher(tmp_path: Path, fake_exit: int, packages: list[str]) -> tuple[subprocess.CompletedProcess[str], str]:
    output = tmp_path / "output"
    output.mkdir()
    for name in packages:
        (output / name).write_text("package")

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    (bin_dir / "rattler-build").write_text(
        "#!/usr/bin/env bash\n"
        "printf '%s\\n' \"$@\"\n"
        f"exit {fake_exit}\n"
    )
    (bin_dir / "rattler-build").chmod(0o755)
    manifest = tmp_path / "manifest.tsv"
    env = {**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}"}
    result = subprocess.run(
        [str(SCRIPT), str(output), "rg-forge", str(manifest)],
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
    return result, manifest.read_text()


def test_empty_output_fails_closed(tmp_path: Path) -> None:
    result, manifest = run_publisher(tmp_path, 0, [])

    assert result.returncode != 0
    assert manifest == "failed\tNO_PACKAGES\n"


def test_existing_package_upload_is_successful(tmp_path: Path) -> None:
    result, manifest = run_publisher(tmp_path, 0, ["pkg.conda"])

    assert result.returncode == 0
    assert "--skip-existing\n" in result.stdout
    assert "-c\nrg-forge\n" in result.stdout
    assert manifest.endswith("uploaded\t" + str(tmp_path / "output" / "pkg.conda") + "\n")


def test_real_upload_failure_is_propagated(tmp_path: Path) -> None:
    result, manifest = run_publisher(tmp_path, 7, ["pkg.tar.bz2"])

    assert result.returncode != 0
    assert manifest.endswith("failed\t" + str(tmp_path / "output" / "pkg.tar.bz2") + "\n")
