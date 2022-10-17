from subprocess import run

import pytest

IMPLEMENTATIONS_TO_TRY = ["apptainer", "singularity"]


@pytest.mark.parametrize("implementation", IMPLEMENTATIONS_TO_TRY)
def test_oci(implementation):
    cmd = [implementation, "exec", "docker://centos:7"]
    cmd += ["bash", "-c", "echo Hello world $(( 1+1 ))!"]
    proc = run(cmd, capture_output=True, check=True, text=True)
    assert proc.stdout == "Hello world 2!\n"


@pytest.mark.parametrize("implementation", IMPLEMENTATIONS_TO_TRY)
def test_build_image(implementation, tmp_path):
    cmd = [implementation, "build", "--fix-perms", "--sandbox"]
    cmd += [tmp_path / "container", "docker://centos:7"]
    run(cmd, capture_output=True, check=True, text=True)
    assert (tmp_path / "container" / "bin").is_dir()
    assert (tmp_path / "container" / "bin" / "bash").is_file()


@pytest.mark.parametrize("implementation", IMPLEMENTATIONS_TO_TRY)
def test_singularity_ce(implementation, tmp_path):
    test_build_image(implementation, tmp_path)

    (tmp_path / "work").mkdir()
    (tmp_path / "home").mkdir()
    (tmp_path / "cvmfs").mkdir()

    cmd = [implementation, "exec", "--contain", "--ipc", "--pid", "--userns"]
    cmd += ["--workdir", tmp_path / "work", "--home", tmp_path / "home"]
    cmd += ["--bind", tmp_path / "cvmfs", tmp_path / "container"]
    cmd += ["bash", "-c", "echo Hello world $(( 1+1+1 ))!"]
    proc = run(cmd, capture_output=True, check=True, text=True)
    assert proc.stdout == "Hello world 3!\n"
