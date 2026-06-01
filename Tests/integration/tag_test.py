"""
apfel-tag integration tests - end-to-end against the release binary.

Model-dependent (Apple Intelligence). Skipped only if the model is unavailable.
Run: python3 -m pytest Tests/integration/ -v
"""

import functools
import json
import os
import pathlib
import subprocess

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[2]
BINARY = ROOT / ".build" / "release" / "apfel-tag"
TIMEOUT = 60


def run(text=None, args=None, timeout=TIMEOUT):
    return subprocess.run(
        [str(BINARY)] + (args or []),
        input=text, text=True, capture_output=True, timeout=timeout,
    )


@functools.lru_cache(maxsize=1)
def model_available():
    # `--version` works without the model; probe the model with a tiny tag run.
    if not BINARY.exists():
        return False
    r = run("hello world", ["--permissive"], timeout=30)
    return r.returncode == 0


pytestmark = pytest.mark.skipif(
    not BINARY.exists() or not model_available(),
    reason="apfel-tag binary or Apple Intelligence not available",
)

SWEEP = [
    "The headphones sound amazing and the battery lasts all day.",
    "Mix flour, eggs, and sugar, then bake at 180C for 25 minutes.",
    "Kubernetes pods keep crashing with OOMKilled under sustained load.",
    "Our Q3 revenue grew twelve percent driven by enterprise subscriptions.",
    "A hiking trip through the Alps with stunning views and great weather.",
    "The central bank raised interest rates by half a percent today.",
    "She practiced the violin for two hours before the concert.",
    "Install the dependencies, run the migrations, then start the dev server.",
    "The soup needs more salt and a squeeze of fresh lemon juice.",
    "Quarterly sales report shows strong growth in the European market.",
]


# --- version / help (model-free, but covered here) ---

def test_version():
    r = run(args=["--version"])
    assert r.returncode == 0
    assert r.stdout.strip().startswith("apfel-tag v")


def test_help():
    r = run(args=["--help"])
    assert r.returncode == 0
    assert "USAGE" in r.stdout and "--kind" in r.stdout


# --- plain ---

def test_plain_returns_tags():
    r = run("The new espresso machine pulls a great shot.", ["--permissive"])
    assert r.returncode == 0, r.stderr
    assert r.stdout.strip(), "expected tags"


def test_plain_one_tag_per_line():
    r = run("A documentary about deep-sea creatures and bioluminescence.", ["--permissive"])
    assert r.returncode == 0
    lines = [l for l in r.stdout.splitlines() if l.strip()]
    assert len(lines) >= 1
    assert not r.stdout.strip().startswith("{")


# --- json ---

def test_json_structure():
    r = run("Kubernetes pods keep crashing under load.", ["-o", "json", "--permissive"])
    assert r.returncode == 0, r.stderr
    payload = json.loads(r.stdout)
    assert isinstance(payload.get("tags"), list) and payload["tags"]
    assert all(isinstance(t, str) and t for t in payload["tags"])


def test_output_long_flag():
    r = run("Enterprise SaaS subscription revenue grew.", ["--output", "json", "--permissive"])
    assert r.returncode == 0
    assert "tags" in json.loads(r.stdout)


def test_json_dedup():
    r = run("Alps hiking trip, mountain views, hiking and more hiking.", ["-o", "json", "--permissive"])
    assert r.returncode == 0
    tags = json.loads(r.stdout)["tags"]
    assert len(tags) == len(set(t.lower() for t in tags))


# --- extra powers ---

def test_max_tags_caps():
    r = run("databases, networking, security, kubernetes, observability, scaling, latency",
            ["-o", "json", "--max-tags", "2", "--permissive"])
    assert r.returncode == 0, r.stderr
    assert len(json.loads(r.stdout)["tags"]) <= 2


def test_kind_emotions():
    r = run("I am absolutely thrilled and grateful for this wonderful surprise!",
            ["--kind", "emotions", "--permissive"])
    assert r.returncode == 0, r.stderr
    assert r.stdout.strip()


def test_kind_all_json_has_categories():
    r = run("An exciting hiking adventure through the Alps with friends.",
            ["--kind", "all", "-o", "json", "--permissive"])
    assert r.returncode == 0, r.stderr
    payload = json.loads(r.stdout)
    assert set(payload.keys()) == {"topics", "emotions", "actions"}
    assert all(isinstance(v, list) for v in payload.values())


def test_invalid_kind_rejected():
    r = run("hello", ["--kind", "vibes"])
    assert r.returncode == 2
    assert "invalid kind" in r.stderr


def test_invalid_output_rejected():
    r = run("hello", ["-o", "yaml"])
    assert r.returncode == 2


# --- input handling ---

def test_empty_stdin_exits_2():
    r = run("")
    assert r.returncode == 2
    assert "no input" in r.stderr.lower()


def test_whitespace_only_exits_2():
    r = run("   \n\t \n")
    assert r.returncode == 2


def test_no_color_env_accepted():
    env = os.environ.copy(); env["NO_COLOR"] = "1"
    r = subprocess.run([str(BINARY), "--permissive"], input="A quiet rainy afternoon.",
                       text=True, capture_output=True, timeout=TIMEOUT, env=env)
    assert r.returncode == 0, r.stderr


# --- sweep ---

@pytest.mark.parametrize("text", SWEEP)
def test_sweep_plain(text):
    r = run(text, ["--permissive"])
    assert r.returncode == 0, f"{text!r}: {r.stderr}"
    assert r.stdout.strip()


@pytest.mark.parametrize("text", SWEEP)
def test_sweep_json(text):
    r = run(text, ["-o", "json", "--permissive"])
    assert r.returncode == 0, f"{text!r}: {r.stderr}"
    assert json.loads(r.stdout)["tags"]
