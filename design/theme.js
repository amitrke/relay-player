// Relay Player — shared runtime theme. Screens read colours from CSS variables only.
(function () {
  const THEMES = {
    Midnight: { stage: '#06060a', bg: '#0a0a0c', surface: '#121215', line: '#24242a', ink: '#f2f2f4', dim: '#9a9aa4' },
    Slate:    { stage: '#0d1014', bg: '#14171c', surface: '#1c2027', line: '#2c323b', ink: '#eef1f5', dim: '#939ba7' },
    Daylight: { stage: '#ececed', bg: '#f7f7f8', surface: '#ffffff', line: '#e2e2e6', ink: '#17171a', dim: '#6b6b73' },
    Amber:    { stage: '#0f0d0a', bg: '#14110d', surface: '#1c1813', line: '#2e2820', ink: '#f5f0e8', dim: '#a89c8a' }
  };

  function lum(hex) {
    const c = hex.replace('#', '');
    const v = [0, 2, 4].map(function (i) {
      const s = parseInt(c.slice(i, i + 2), 16) / 255;
      return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2];
  }

  function ratio(a, b) {
    const l = [lum(a), lum(b)].sort(function (m, n) { return n - m; });
    return (l[0] + 0.05) / (l[1] + 0.05);
  }

  window.RelayTheme = {
    themes: THEMES,
    // Accent ink is derived, never hard-coded: whichever of white/dark ink
    // clears 4.5:1 against the chosen accent wins.
    apply: function (el, themeName, accent) {
      if (!el) return;
      const t = THEMES[themeName] || THEMES.Midnight;
      const a = accent || '#8b7fe0';
      const dark = '#121216';
      const set = {
        '--stage': t.stage, '--bg': t.bg, '--surface': t.surface, '--line': t.line,
        '--ink': t.ink, '--ink-dim': t.dim, '--accent': a,
        '--accent-ink': ratio('#ffffff', a) >= ratio(dark, a) ? '#ffffff' : dark
      };
      Object.keys(set).forEach(function (k) { el.style.setProperty(k, set[k]); });
    }
  };
})();
