"""
Deterministic 2-pebble automaton simulator
Language: L = { c^k w^k | w is a palindrome }

Assumption:
    'c' is a separator/counting symbol and does not occur in w.
Model:
    - two-way input movement
    - pebbles may be lifted/repositioned
    - deterministic
    - two reusable pebbles

The visualization uses matplotlib.
"""

import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from dataclasses import dataclass


@dataclass
class Step:
    phase: str
    head: int
    p1: int | None
    p2: int | None
    message: str
    status: str = "RUNNING"


class TwoPebbleAutomaton:
    def __init__(self, word: str):
        self.word = word
        self.n = len(word)
        self.steps: list[Step] = []
        self.accepted = False
        self._run()

    def add(self, phase, head, p1, p2, message, status="RUNNING"):
        self.steps.append(Step(phase, head, p1, p2, message, status))

    def reject(self, phase, head, p1, p2, message):
        self.add(phase, head, p1, p2, message, "REJECT")

    def accept(self, phase, head, p1, p2, message):
        self.add(phase, head, p1, p2, message, "ACCEPT")
        self.accepted = True

    def _run(self):
        w = self.word

        if not w:
            self.reject("START", 0, None, None, "Empty input is not in the language.")
            return

        # ------------------------------------------------------------
        # PHASE 1: verify c^k w^k
        #
        # P1 scans the c-block.
        # P2 scans the w-block.
        # They advance one position per comparison.
        # ------------------------------------------------------------

        k = 0
        while k < self.n and w[k] == "c":
            k += 1

        if k == 0:
            self.reject("FORMAT", 0, None, None,
                        "Input must start with a non-empty c^k block.")
            return

        if k == self.n:
            self.reject("FORMAT", k, k - 1, None,
                        "There is no w-block.")
            return

        # Because c is reserved for the first block, w cannot contain c.
        if "c" in w[k:]:
            self.reject("FORMAT", k, k - 1, k,
                        "Symbol c appears inside w; assumed alphabet excludes c from w.")
            return

        p1 = 0
        p2 = k
        head = 0

        self.add("LENGTH", head, p1, p2,
                 f"Boundary found: c^k with k={k}. Compare |c^k| with |w|.")

        # Lockstep comparison. The pebbles are markers; they are reused later.
        while p1 < k and p2 < self.n:
            self.add("LENGTH", head, p1, p2,
                     f"Compare c at position {p1 + 1} with w at position {p2 + 1}.")
            p1 += 1
            p2 += 1
            head = p2 if p2 < self.n else self.n - 1

        if p1 != k or p2 != self.n:
            self.reject("LENGTH", head, p1, min(p2, self.n - 1),
                        "The two blocks have different lengths.")
            return

        self.add("LENGTH", head, p1 - 1, self.n - 1,
                 f"Length check passed: |c^k| = |w| = {k}.")

        # ------------------------------------------------------------
        # PHASE 2: reuse the same two pebbles to check palindrome.
        #
        # P1 = left end of w
        # P2 = right end of w
        # Compare, then move inward.
        # ------------------------------------------------------------

        left = k
        right = self.n - 1
        p1 = left
        p2 = right
        head = left

        self.add("PALINDROME", head, p1, p2,
                 "Reuse the two pebbles: P1=left end of w, P2=right end of w.")

        while left < right:
            a = w[left]
            b = w[right]

            self.add("PALINDROME", head, left, right,
                     f"Compare w[{left - k + 1}]={a!r} with "
                     f"w[{right - k + 1}]={b!r}.")

            if a != b:
                self.reject("PALINDROME", head, left, right,
                            f"Mismatch: {a!r} != {b!r}. w is not a palindrome.")
                return

            left += 1
            right -= 1
            p1 = left
            p2 = right
            head = left

            if left <= right:
                self.add("PALINDROME", head, p1, p2,
                         "Move both pebbles one position toward the center.")

        self.accept("ACCEPT", head, p1, p2,
                    "All mirrored symbols match. Input is in L.")

    def run_visualization(self, interval=1100):
        """Animate the computation with matplotlib."""
        fig, ax = plt.subplots(figsize=(12, 4.8))
        fig.canvas.manager.set_window_title("Deterministic 2-Pebble Automaton")

        positions = list(range(self.n))
        symbols = list(self.word)

        def draw(frame):
            ax.clear()

            step = self.steps[frame]

            # Input tape
            ax.set_xlim(-1, max(self.n, 2))
            ax.set_ylim(-2.8, 3.2)
            ax.set_xticks(positions)
            ax.set_xticklabels([str(i + 1) for i in positions])
            ax.set_yticks([])
            ax.set_xlabel("Input positions (1-indexed)")
            ax.set_title("Deterministic 2-Pebble Automaton", fontsize=15)

            for i, ch in enumerate(symbols):
                ax.text(i, 1.8, ch, ha="center", va="center",
                        fontsize=18, fontweight="bold")
                ax.plot([i - 0.38, i + 0.38], [1.35, 1.35], linewidth=1)

            # Mark c/w boundary
            k = 0
            while k < self.n and self.word[k] == "c":
                k += 1

            if 0 < k < self.n:
                ax.axvline(k - 0.5, linestyle="--", linewidth=1)
                ax.text(k - 0.5, 2.55, "boundary", ha="center", fontsize=9)

            # Pebbles
            pebble_info = [
                (step.p1, "P1", 0.65),
                (step.p2, "P2", -0.05),
            ]

            for pos, label, y in pebble_info:
                if pos is not None and 0 <= pos < self.n:
                    ax.scatter([pos], [y], s=500, marker="o",
                               edgecolors="black", linewidths=1.2)
                    ax.text(pos, y, label, ha="center", va="center",
                            fontsize=10, fontweight="bold")

            # Head
            if 0 <= step.head < self.n:
                ax.scatter([step.head], [-0.9], s=260, marker="v")
                ax.text(step.head, -1.25, "HEAD", ha="center", fontsize=9)

            # Phase
            phase_text = {
                "LENGTH": "PHASE 1 — verify |c^k| = |w|",
                "PALINDROME": "PHASE 2 — verify w is a palindrome",
                "ACCEPT": "ACCEPT",
                "FORMAT": "FORMAT CHECK",
                "START": "START",
            }.get(step.phase, step.phase)

            status = step.status
            status_suffix = f"   [{status}]"

            ax.text(
                0.01, 0.98,
                phase_text + status_suffix,
                transform=ax.transAxes,
                ha="left", va="top",
                fontsize=12, fontweight="bold"
            )

            ax.text(
                0.01, 0.04,
                step.message,
                transform=ax.transAxes,
                ha="left", va="bottom",
                fontsize=11
            )

            # Explanation of pebble roles
            if step.phase == "LENGTH":
                role = "P1 scans c^k  ↔  P2 scans w^k"
            elif step.phase == "PALINDROME":
                role = "P1 = left end of w  ↔  P2 = right end of w"
            else:
                role = "Two pebbles reused"

            ax.text(
                0.99, 0.98, role,
                transform=ax.transAxes,
                ha="right", va="top",
                fontsize=10
            )

            ax.set_frame_on(False)

        # Store reference as self.anim to prevent garbage collection
        self.anim = FuncAnimation(
            fig,
            draw,
            frames=len(self.steps),
            interval=interval,
            repeat=False,
        )

        plt.tight_layout()
        plt.show()
        return self.anim
    
def recognize(word: str, visualize=True):
    automaton = TwoPebbleAutomaton(word)

    print("=" * 60)
    print("2-PEBBLE AUTOMATON")
    print(f"Input: {word!r}")
    print(f"Result: {'ACCEPT' if automaton.accepted else 'REJECT'}")
    print("=" * 60)

    if visualize:
        automaton.run_visualization()

    return automaton.accepted


if __name__ == "__main__":
    # Examples:
    recognize("cccabbaabbab")     # ccc + aba -> ACCEPT
    # recognize("ccccabba") # cccc + abba -> ACCEPT
    # recognize("cccabc")   # ccc + abc -> REJECT
    #recognize("ccab")     # cc + ab -> REJECT
