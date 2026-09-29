module.exports = function (eleventyConfig) {
  eleventyConfig.addPassthroughCopy("src/assets");
  // Google Search Console ownership file. It has to sit at the site root byte for byte;
  // left to Eleventy as a template it would also be published at /googleb8fc2c9df817cee0/,
  // hence the ignore alongside the passthrough.
  eleventyConfig.addPassthroughCopy("src/googleb8fc2c9df817cee0.html");
  eleventyConfig.ignores.add("src/googleb8fc2c9df817cee0.html");

  // GitHub Pages reads the custom domain from a CNAME file at the root of the
  // deployed site. It has no extension, so Eleventy would not pick it up as a
  // template either -- without the passthrough it never reaches _site.
  eleventyConfig.addPassthroughCopy("src/CNAME");

  // Keep documentation out of src/. `ignores` only governs template processing —
  // anything under src/assets is copied verbatim by the passthrough above, so a
  // stray .md in there ships to the live site. Image credits live in docs/.
  eleventyConfig.ignores.add("src/assets/**/*.md");

  eleventyConfig.addFilter("year", () => new Date().getFullYear());

  // Group papers into decades, newest first, for the Research page rail.
  eleventyConfig.addFilter("byDecade", (items) => {
    const buckets = new Map();
    const sorted = [...items].sort((a, b) => b.year - a.year);
    for (const item of sorted) {
      const decade = Math.floor(item.year / 10) * 10;
      if (!buckets.has(decade)) buckets.set(decade, []);
      buckets.get(decade).push(item);
    }
    return [...buckets.entries()]
      .sort((a, b) => b[0] - a[0])
      .map(([decade, items]) => ({ label: `${decade}s`, items }));
  });

  return {
    dir: {
      input: "src",
      output: "_site",
      includes: "_includes",
      data: "_data",
    },
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk",
  };
};
