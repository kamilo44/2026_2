import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from dataclasses import dataclass


@dataclass
class Step:
    phase: str
    head: int
    p1: int | None  # Counter pebble in c^k
    p2: int | None  # Start of current palindrome w_i
    p3: int | None  # Candidate end boundary of w_i
    p4: int | None  # Left palindrome scanning head
    p5: int | None  # Right palindrome scanning head
    message: str
    status: str = "RUNNING"


class PebbleAutomaton:
    """
    Nondeterministic 5-Pebble Automaton Simulator for:
    L = { c^k w_1 w_2 ... w_k | k >= 1 and every w_i is a palindrome }
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

    def _run(self):
        w = self.word
        if not w:
            self.reject("START", 0, None, None, None, None, None, "Empty string is not in L.")
            return

        # Phase 1: Format check & locate c^k prefix
        k = 0
        while k < self.n and w[k] == "c":
            k += 1

        if k == 0:
            self.reject("FORMAT", 0, None, None, None, None, None, "Input must start with at least one 'c'.")
            return

        if k == self.n:
            self.reject("FORMAT", k - 1, 0, None, None, None, None, "No suffix w after c^k block.")
            return

        if "c" in w[k:]:
            c_pos = w.find("c", k)
            self.reject("FORMAT", c_pos, None, None, None, None, None, f"Symbol 'c' found inside suffix at index {c_pos + 1}.")
            return

        self.add("START", 0, 0, k, None, None, None,
                 f"Prefix c^{k} found (k={k}). Searching for {k} palindromes in suffix w[{k + 1}:{self.n}].")

        # Phase 2: Nondeterministic search using 5 pebbles
        success = self._search_palindromes(k, start=k, count_idx=0)

        if not success and not self.accepted:
            self.reject("FAIL", self.n - 1, k - 1, None, None, None, None,
                        f"Could not partition suffix into {k} palindromes.")

    def _check_palindrome(self, count_idx, start, end):
        """Use P4 and P5 to verify whether w[start:end] is a palindrome."""
        p4 = start
        p5 = end - 1

        self.add("PAL_CHECK", p4, count_idx, start, end, p4, p5,
                 f"Testing segment w[{start + 1}:{end}] ('{self.word[start:end]}') for Palindrome #{count_idx + 1}.")

        while p4 < p5:
            c4 = self.word[p4]
            c5 = self.word[p5]
            if c4 != c5:
                self.add("PAL_CHECK", p4, count_idx, start, end, p4, p5,
                         f"Mismatch: w[{p4 + 1}]='{c4}' != w[{p5 + 1}]='{c5}'. Not a palindrome.")
                return False

            self.add("PAL_CHECK", p4, count_idx, start, end, p4, p5,
                     f"Match: '{c4}' at positions {p4 + 1} and {p5 + 1}. Moving pointers inward.")
            p4 += 1
            p5 -= 1

        self.add("PAL_CHECK", p4, count_idx, start, end, max(start, p4), min(end - 1, p5),
                 f"Segment w[{start + 1}:{end}] ('{self.word[start:end]}') is a valid palindrome!")
        return True

    def _search_palindromes(self, k, start, count_idx):
        if self.accepted:
            return True

        rem = k - count_idx
        if (self.n - start) < rem:
            return False

        if rem == 1:
            # Last palindrome must consume all remaining symbols
            boundary = self.n
            self.add("SEARCH", start, count_idx, start, boundary, None, None,
                     f"Palindrome #{count_idx + 1} (last) must span w[{start + 1}:{boundary}].")

            if self._check_palindrome(count_idx, start, boundary):
                self.accept("ACCEPT", boundary - 1, count_idx, start, boundary, None, None,
                            f"Successfully partitioned suffix into {k} palindromes!")
                return True
            return False

        # Try possible nondeterministic boundaries
        for boundary in range(start + 1, self.n - rem + 2):
            self.add("SEARCH", start, count_idx, start, boundary, None, None,
                     f"Trying boundary {boundary} for Palindrome #{count_idx + 1} (w[{start + 1}:{boundary}]).")

            if self._check_palindrome(count_idx, start, boundary):
                if self._search_palindromes(k, start=boundary, count_idx=count_idx + 1):
                    return True

                self.add("BACKTRACK", start, count_idx, start, boundary, None, None,
                         f"Backtracking from boundary {boundary} for Palindrome #{count_idx + 1}.")

        return False

    def run_visualization(self, interval=1100):
        """Animate the 5-pebble computation using matplotlib."""
        fig, ax = plt.subplots(figsize=(13, 5.2))
        fig.canvas.manager.set_window_title("5-Pebble Automaton: k-Palindromes")

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
            ax.set_title("Nondeterministic 5-Pebble Automaton Simulator", fontsize=14, fontweight="bold")

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
                    # Offset overlapping P4 and P5
                    y_adj = y
                    if label.startswith("P5") and step.p4 == step.p5:
                        y_adj += 0.3

                    ax.scatter([pos], [y_adj], s=550, color=color, edgecolors="black", linewidths=1.2, zorder=5)
                    ax.text(pos, y_adj, label.split()[0], ha="center", va="center", color="white", fontsize=9, fontweight="bold", zorder=6)

            # Tape Head
            if 0 <= step.head < self.n:
                ax.scatter([step.head], [-1.4], s=240, marker="v", color="#333333")
                ax.text(step.head, -1.75, "HEAD", ha="center", fontsize=8, fontweight="bold")

            # Phase and status banner
            phase_text = {
                "START": "PHASE 0 — Scan c^k Prefix",
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

            # Pebble Legend
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
    automaton = PebbleAutomaton(word)

    print("=" * 60)
    print("5-PEBBLE AUTOMATON")
    print(f"Input: {word!r}")
    print(f"Result: {'ACCEPT' if automaton.accepted else 'REJECT'}")
    print("=" * 60)

    if visualize:
        automaton.run_visualization()

    return automaton.accepted


if __name__ == "__main__":
    # Test Cases:
    recognize("cccabbaabbab")        # k=2: 'aba' (pal) + '0' (pal) -> ACCEPT
    # recognize("cccaba011")    # k=3: 'aba' + '0' + '11' -> ACCEPT
    # recognize("cccaba01001")  # k=3: 'aba' + '0' + '1001' -> ACCEPT
    # recognize("cc010")        # k=2: '0' + '10' (not pal) -> REJECT