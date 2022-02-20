module.exports = {
  important: true,
  purge: {
    // Specify the paths to all of the template files in your project
    content: [
      "./src/Contexts/**/*.res",
      "./src/QueryRenderers/**/*.res",
      "./src/Components/**/*.res",
      "./src/Containers/**/*.res",
      "./src/*.res",
    ],
    options: {
      safelist: ["html", "body"],
    },
  },
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      listStyleType: {
        circle: "circle",
      },
      colors: {
        themePrimary: "#212121",
        black: "#000",
        alertRed: "#fdecea",
        darkPrimary: "rgba(0, 0, 0, .87)",
        darkSecondary: "rgba(0, 0, 0, .60)",
        darkDisabled: "rgba(0, 0, 0, .38)",
        darkBorder: "rgba(229, 231, 235)",
        darkDivider: "rgba(0, 0, 0, .12)",
        lightPrimary: "rgba(255, 255, 255, .87)",
        lightSecondary: "rgba(255, 255, 255, .60)",
        lightDisabled: "rgba(255, 255, 255, .38)",
      },
    },
    screens: {
      sm: { max: "639px" },
    },
    fontSize: {
      xs: ".75rem",
      sm: ".875rem",
      base: "1rem",
      lg: "1.125rem",
      xl: "1.25rem",
      "2xl": "1.5rem",
      "3xl": "1.875rem",
      "4xl": "2.25rem",
      "5xl": "3rem",
      "6xl": "4rem",
    },
    minWidth: {
      28: "7rem",
    },
    fontFamily: {
      sans: [
        "-apple-system",
        "BlinkMacSystemFont",
        "Helvetica Neue",
        "Arial",
        "sans-serif",
      ],
      serif: [
        "Georgia",
        "-apple-system",
        "BlinkMacSystemFont",
        "Helvetica Neue",
        "Arial",
        "sans-serif",
      ],
      mono: [
        "IBM Plex Mono",
        "Menlo",
        "Monaco",
        "Consolas",
        "Roboto Mono",
        "SFMono-Regular",
        "Segoe UI",
        "Courier",
        "monospace",
      ],
    },
  },
  variants: {
    width: ["responsive"],
  },
  plugins: [],
};
