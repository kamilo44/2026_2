import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from dataclasses import dataclass


@dataclass
class Step:
    phase: str
    head: int
    p1: int | None  # Counter pebble in c^k
    p2: int | None  # Start position of current palindrome w_i
    p3: int | None  # Candidate end boundary for w_i
    p4: int | None  # Left match pointer
    p5: int | None  # Right match pointer
    message: str
    status: str = "RUNNING"


class DeterministicPebbleAutomaton:
    """
    Deterministic 5-Pebble Automaton Simulator
    Language: L = { c^k w_1 w_2 ... w_k | k >= 1 and every w_i is a palindrome }
    Alphabet: {c, 0, 1} where 'c' only appears in the initial c^k prefix.
    """

    def __init__(self, word: str):
        self.word = word
        self.n = len(word)
        self.steps: list[Step] = []
        self.accepted = False
        self._run()

    def add(self, phase, head, p1, p2, p3, p4, p5, message, status="RUNNING"):
        self.steps.append(Step(phase, head, p1, p2, p3, p4, p5, message, status))

    def reject(self, phase, head, p1, p2, p3, p4, p5, message):
        self.add(phase, head, p1, p2, p3, p4, p5, message, "REJECT")

    def accept(self, phase, head, p1, p2, p3, p4, p5, message):
        self.add(phase, head, p1, p2, p3, p4, p5, message, "ACCEPT")
        self.accepted = True

    def _is_palindrome_stepwise(self, start: int, end: int, count_idx: int) -> bool:
        """Deterministically check whether w[start:end] is a palindrome using P4 and P5."""
        p4 = start
        p5 = end - 1

        self.add(
            "PAL_CHECK", p4, count_idx, start, end, p4, p5,
            f"Testing segment w[{start + 1}:{end}] ('{self.word[start:end]}') for Palindrome #{count_idx + 1}."
        )

        while p4 < p5:
            c4 = self.word[p4]
            c5 = self.word[p5]
            if c4 != c5:
                self.add(
                    "PAL_CHECK", p4, count_idx, start, end, p4, p5,
                    f"Mismatch: w[{p4 + 1}]='{c4}' != w[{p5 + 1}]='{c5}'. Not a palindrome."
                )
                return False

            self.add(
                "PAL_CHECK", p4, count_idx, start, end, p4, p5,
                f"Match: '{c4}' at positions {p4 + 1} and {p5 + 1}. Moving pointers inward."
            )
            p4 += 1
            p5 -= 1

        self.add(
            "PAL_CHECK", p4, count_idx, start, end, max(start, p4), min(end - 1, p5),
            f"Segment w[{start + 1}:{end}] ('{self.word[start:end]}') is a valid palindrome!"
        )
        return True

    def _run(self):
        w = self.word
        if not w:
            self.reject("START", 0, None, None, None, None, None, "Empty input is not in L.")
            return

        # ------------------------------------------------------------
        # PHASE 1: Verify c^k prefix format
        # ------------------------------------------------------------
        k = 0
        while k < self.n and w[k] == "c":
            k += 1

        if k == 0:
            self.reject("FORMAT", 0, None, None, None, None, None, "Input must start with at least one 'c'.")
            return

        if k == self.n:
            self.reject("FORMAT", k - 1, k - 1, None, None, None, None, "No suffix w after c^k block.")
            return

        if "c" in w[k:]:
            c_pos = w.find("c", k)
            self.reject("FORMAT", c_pos, None, None, None, None, None,
                        f"Symbol 'c' appears inside suffix w at position {c_pos + 1}.")
            return

        self.add("START", 0, 0, k, None, None, None,
                 f"Prefix c^{k} verified (k={k}). Seeking {k} palindromes in suffix w[{k + 1}:{self.n}].")

        # ------------------------------------------------------------
        # PHASE 2: Deterministic Backtracking Search
        # Explicit stack frame: (start_pos, boundary_tried)
        # ------------------------------------------------------------
        stack: list[tuple[int, int]] = []
        curr_start = k
        next_boundary = k + 1

        while True:
            depth = len(stack)  # Index of palindrome currently being matched (0 to k-1)

            # CASE A: Final palindrome (depth == k - 1)
            if depth == k - 1:
                boundary = self.n
                self.add("SEARCH", curr_start, depth, curr_start, boundary, None, None,
                         f"Palindrome #{depth + 1} (last) must extend from position {curr_start + 1} to end {boundary}.")

                if curr_start < self.n and self._is_palindrome_stepwise(curr_start, boundary, depth):
                    self.accept("ACCEPT", boundary - 1, depth, curr_start, boundary, None, None,
                                f"Successfully partitioned w into {k} palindromes!")
                    return
                else:
                    self.add("BACKTRACK", curr_start, depth, curr_start, boundary, None, None,
                             f"Last segment w[{curr_start + 1}:{boundary}] failed. Backtracking.")

                    if not stack:
                        self.reject("FAIL", self.n - 1, k - 1, None, None, None, None,
                                    f"Exhausted choices. Input cannot be partitioned into {k} palindromes.")
                        return

                    curr_start, tried_boundary = stack.pop()
                    next_boundary = tried_boundary + 1
                    continue

            # CASE B: Intermediate palindrome (depth < k - 1)
            rem_palindromes = k - depth
            max_boundary = self.n - rem_palindromes + 1

            found_valid_step = False
            for b in range(next_boundary, max_boundary + 1):
                self.add("SEARCH", curr_start, depth, curr_start, b, None, None,
                         f"Trying boundary {b} for Palindrome #{depth + 1} (segment w[{curr_start + 1}:{b}]).")

                if self._is_palindrome_stepwise(curr_start, b, depth):
                    stack.append((curr_start, b))
                    curr_start = b
                    next_boundary = b + 1
                    found_valid_step = True
                    break

            if not found_valid_step:
                self.add("BACKTRACK", curr_start, depth, curr_start, None, None, None,
                         f"No valid boundary from position {curr_start + 1} yields a solution. Backtracking.")

                if not stack:
                    self.reject("FAIL", self.n - 1, k - 1, None, None, None, None,
                                f"Exhausted choices. Input cannot be partitioned into {k} palindromes.")
                    return

                curr_start, tried_boundary = stack.pop()
                next_boundary = tried_boundary + 1

    def run_visualization(self, interval=1100):
        """Animate the deterministic computation using matplotlib."""
        fig, ax = plt.subplots(figsize=(13, 5.2))
        fig.canvas.manager.set_window_title("Deterministic 5-Pebble Automaton")

        positions = list(range(self.n))
        symbols = list(self.word)

        def draw(frame):
            ax.clear()
            step = self.steps[frame]

            ax.set_xlim(-1, max(self.n + 1, 3))
            ax.set_ylim(-2.2, 3.4)
            ax.set_xticks(range(self.n + 1))
            ax.set_xticklabels([str(i + 1) for i in positions] + ["END"])
            ax.set_yticks([])
            ax.set_xlabel("Tape positions (1-indexed)")
            ax.set_title("Deterministic 5-Pebble Automaton Simulator", fontsize=14, fontweight="bold")

            # Tape characters
            for i, ch in enumerate(symbols):
                ax.text(i, 1.8, ch, ha="center", va="center", fontsize=16, fontweight="bold")
                ax.plot([i - 0.38, i + 0.38], [1.35, 1.35], color="#555555", linewidth=1)

            # c^k boundary line
            k = 0
            while k < self.n and self.word[k] == "c":
                k += 1

            if 0 < k < self.n:
                ax.axvline(k - 0.5, linestyle="--", color="gray", linewidth=1.2)
                ax.text(k - 0.5, 3.0, "c^k | w boundary", ha="center", fontsize=9, style="italic")

            # Display Pebbles
            pebble_info = [
                (step.p1, "P1 (Count)", 0.65, "#1f77b4"),    # Blue
                (step.p2, "P2 (Start)", -0.05, "#2ca02c"),   # Green
                (step.p3, "P3 (Bound)", -0.75, "#ff7f0e"),   # Orange
                (step.p4, "P4 (L-Pal)", 2.45, "#9467bd"),    # Purple
                (step.p5, "P5 (R-Pal)", 2.45, "#d62728"),    # Red
            ]

            for pos, label, y, color in pebble_info:
                if pos is not None and 0 <= pos <= self.n:
                    y_adj = y
                    if label.startswith("P5") and step.p4 == step.p5:
                        y_adj += 0.35

                    ax.scatter([pos], [y_adj], s=550, color=color, edgecolors="black", linewidths=1.2, zorder=5)
                    ax.text(pos, y_adj, label.split()[0], ha="center", va="center", color="white", fontsize=9, fontweight="bold", zorder=6)

            # Tape Head
            if 0 <= step.head < self.n:
                ax.scatter([step.head], [-1.4], s=240, marker="v", color="#333333")
                ax.text(step.head, -1.75, "HEAD", ha="center", fontsize=8, fontweight="bold")

            # Phase and status banner
            phase_text = {
                "START": "PHASE 0 — Verify c^k Prefix",
                "SEARCH": "PHASE 1 — Boundary Choice",
                "PAL_CHECK": "PHASE 2 — Palindrome Check",
                "BACKTRACK": "PHASE 3 — Backtrack Boundary",
                "ACCEPT": "ACCEPT",
                "FAIL": "REJECT",
                "FORMAT": "FORMAT ERROR",
            }.get(step.phase, step.phase)

            ax.text(0.01, 0.96, f"{phase_text}   [{step.status}]",
                    transform=ax.transAxes, ha="left", va="top", fontsize=11, fontweight="bold")

            ax.text(0.01, 0.04, step.message,
                    transform=ax.transAxes, ha="left", va="bottom", fontsize=10)

            ax.text(0.99, 0.96,
                    "P1: c-Counter | P2: Pal Start | P3: Pal End | P4: Left Head | P5: Right Head",
                    transform=ax.transAxes, ha="right", va="top", fontsize=8.5, style="italic")

            ax.set_frame_on(False)

        self.anim = FuncAnimation(
            fig, draw, frames=len(self.steps), interval=interval, repeat=False
        )

        plt.tight_layout()
        plt.show()
        return self.anim


def recognize(word: str, visualize=True):
    automaton = DeterministicPebbleAutomaton(word)

    print("=" * 60)
    print("DETERMINISTIC 5-PEBBLE AUTOMATON")
    print(f"Input: {word!r}")
    print(f"Result: {'ACCEPT' if automaton.accepted else 'REJECT'}")
    print("=" * 60)

    if visualize:
        automaton.run_visualization()

    return automaton.accepted


if __name__ == "__main__":
    tests = [
        "cccabbaabbab",           # ACCEPT (1 palindrome '0')
       # "caba",         # ACCEPT (1 palindrome 'aba')
       # "ccaba0",       # ACCEPT (2 palindromes 'aba', '0')
       # "cccaba01001",  # ACCEPT (3 palindromes 'aba', '0', '1001')
       # "cccaba011",    # ACCEPT (3 palindromes 'aba', '0', '11')
       # "cc010",        # REJECT (cannot split '010' into 2 palindromes)
       # "ccc101011",    # ACCEPT (3 palindromes '1', '010', '11')
    ]

    for test in tests:
        recognize(test, visualize=True)