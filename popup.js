document.getElementById('downloadBtn').addEventListener('click', function() {
    chrome.tabs.executeScript({
      code: 'main.rb'
    });
  });
  