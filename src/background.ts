const NATIVE_HOST = "com.tabbar.toggle";

chrome.commands.onCommand.addListener((command: string) => {
  if (command !== "toggle-vertical-tabs") return;
  chrome.runtime.sendNativeMessage(NATIVE_HOST, { action: "toggle" }, () => {
    if (chrome.runtime.lastError) {
      console.error("native host error:", chrome.runtime.lastError.message);
    }
  });
});
