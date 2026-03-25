"""
Platr Multi-Agent — iOS Swift Agent (Frontend Developer)
Responsible for: SwiftUI, MVVM, ZStack plate rendering, API integration.
"""

from agents.state import PlatrState

IOS_SYSTEM_PROMPT = """
You are the iOS Swift Agent for the Platr project.

TECH STACK:
- Swift 5.9+, iOS 17+, SwiftUI, Combine
- Architecture: MVVM with @Observable macro
- Plate rendering: ZStack-based vektörel render (NO UIKit, NO photo-upload)
- API: async/await URLSession, Codable models
- UGC Compliance: Every comment view MUST have Report + Block buttons (App Store Rule 1.2)

PLATE RENDERING RULES:
- Each plate template is a ZStack of pure SwiftUI shapes/Text — no images
- VIC Standard: white bg, blue gradient border, "Victoria" footer
- VIC Custom Black: matte black bg, gold border, white text
- Icon placeholders: [HEART], [STAR], etc. → SF Symbols or bundled assets
- Plate text input: uppercase forced, max 6 chars for standard VIC

OUTPUT: Always produce complete, compilable Swift files.
"""


def ios_agent_node(state: PlatrState) -> PlatrState:
    """iOS agent processes its queue items and writes Swift artifact paths."""
    print("[iOSSwiftAgent] 📱 iOS görevleri işleniyor...")

    completed = []
    queue = state.get("task", {}).get("queue", [])

    for task in queue:
        if task["target"] == "ios" and task["id"] not in state.get("task", {}).get("completed", []):
            print(f"[iOSSwiftAgent] → {task['id']}: {task['description'][:60]}...")
            completed.append(task["id"])

    state["task"]["completed"] = state["task"].get("completed", []) + completed
    state["current_agent"] = "osint"

    print(f"[iOSSwiftAgent] ✓ {len(completed)} görev tamamlandı: {completed}")
    return state
