import { db } from "./firebase";
import { collection, addDoc } from "firebase/firestore";

const designItems = [
  {
    name: "Business card",
    sizes: ["Standard"],
    creditsPerCreative: 2,
    category: "print",
  },
  {
    name: "Brochure (Bi fold)",
    sizes: ["A4/A5 - 4 pages"],
    creditsPerCreative: 5,
    category: "print",
  },
  {
    name: "Brochure (Tri fold)",
    sizes: ["A4/A5 - 6 pages"],
    creditsPerCreative: 10,
    category: "print",
  },
  {
    name: "Brochure -10 pages",
    sizes: ["A4/A5"],
    creditsPerCreative: 15,
    category: "print",
  },
  {
    name: "Brochure -20 pages",
    sizes: ["A4/A5"],
    creditsPerCreative: 30,
    category: "print",
  },
  { name: "Flyers", sizes: ["A4"], creditsPerCreative: 15, category: "print" },
  { name: "Flyers", sizes: ["A5"], creditsPerCreative: 12, category: "print" },
  { name: "Poster", sizes: ["A3"], creditsPerCreative: 20, category: "print" },
  { name: "Poster", sizes: ["A4"], creditsPerCreative: 15, category: "print" },
  {
    name: "Infographics",
    sizes: ["A4/A5"],
    creditsPerCreative: 10,
    category: "print",
  },
  {
    name: "Booth Backdrops",
    sizes: ["Standard"],
    creditsPerCreative: 20,
    category: "event",
  },
  {
    name: "Standees",
    sizes: ["Standard"],
    creditsPerCreative: 15,
    category: "event",
  },
  {
    name: "ID card",
    sizes: ["Standard"],
    creditsPerCreative: 3,
    category: "print",
  },
  {
    name: "Brand Presentation/Deck - up to 10 slides",
    sizes: ["Standard"],
    creditsPerCreative: 40,
    category: "presentation",
  },
  {
    name: "Pitch Deck - up to 10 slides",
    sizes: ["Standard"],
    creditsPerCreative: 50,
    category: "presentation",
  },
  {
    name: "Brand Deck - up to 20 slides",
    sizes: ["Standard"],
    creditsPerCreative: 80,
    category: "presentation",
  },
  {
    name: "Product Catalog - up to 4 pages",
    sizes: ["A4/A5"],
    creditsPerCreative: 25,
    category: "print",
  },
  {
    name: "Product Catalog - up to 6 pages",
    sizes: ["A4/A5"],
    creditsPerCreative: 35,
    category: "print",
  },
  {
    name: "Product Catalog - up to 10 pages",
    sizes: ["A4/A5"],
    creditsPerCreative: 40,
    category: "print",
  },
  {
    name: "Table Banner",
    sizes: ["Standard"],
    creditsPerCreative: 15,
    category: "event",
  },
  {
    name: "Social media profile picture",
    sizes: ["Standard social media"],
    creditsPerCreative: 2,
    category: "social",
  },
  {
    name: "Social media cover image",
    sizes: ["Standard social media"],
    creditsPerCreative: 5,
    category: "social",
  },
  {
    name: "Emailer",
    sizes: ["Standard"],
    creditsPerCreative: 10,
    category: "digital",
  },
  {
    name: "Ad Creative - static",
    sizes: ["Standard social media"],
    creditsPerCreative: 5,
    category: "social",
  },
  {
    name: "Static social media creative",
    sizes: ["Standard social media"],
    creditsPerCreative: 3,
    category: "social",
  },
  {
    name: "Reels (30 sec)",
    sizes: ["30 sec - no shoot"],
    creditsPerCreative: 10,
    category: "video",
  },
  {
    name: "Reels (60 sec)",
    sizes: ["60 sec - no shoot"],
    creditsPerCreative: 15,
    category: "video",
  },
  {
    name: "Shorts",
    sizes: ["60 sec - YouTube"],
    creditsPerCreative: 10,
    category: "video",
  },
  {
    name: "GIFs",
    sizes: ["Standard social media"],
    creditsPerCreative: 10,
    category: "motion",
  },
  {
    name: "Text-based creative",
    sizes: ["Standard social media"],
    creditsPerCreative: 5,
    category: "social",
  },
  {
    name: "Motion graphics",
    sizes: ["30 sec"],
    creditsPerCreative: 25,
    category: "motion",
  },
  {
    name: "Letterhead",
    sizes: ["A4"],
    creditsPerCreative: 5,
    category: "print",
  },
  {
    name: "Billboards",
    sizes: ["Standard"],
    creditsPerCreative: 20,
    category: "print",
  },
  {
    name: "Carousel creative posts",
    sizes: ["Standard social media"],
    creditsPerCreative: 15,
    category: "social",
  },
  {
    name: "Website Banners",
    sizes: ["Standard"],
    creditsPerCreative: 15,
    category: "web",
  },
  {
    name: "Icons",
    sizes: ["Standard"],
    creditsPerCreative: 5,
    category: "web",
  },
  {
    name: "2D Video Editing",
    sizes: ["Up to 5 minutes"],
    creditsPerCreative: 100,
    category: "video",
  },
  {
    name: "Packaging design",
    sizes: ["As per requirement"],
    creditsPerCreative: 250,
    category: "print",
  },
  {
    name: "Logo designing",
    sizes: ["As per requirement"],
    creditsPerCreative: 300,
    category: "branding",
  },
  {
    name: "Brand Guidebook",
    sizes: ["As per requirement"],
    creditsPerCreative: 400,
    category: "branding",
  },
  {
    name: "Logo Guidebook",
    sizes: ["As per requirement"],
    creditsPerCreative: 350,
    category: "branding",
  },
  {
    name: "Website Landing Page",
    sizes: ["Single page"],
    creditsPerCreative: 500,
    category: "web",
  },
];

export const seedDesignItems = async () => {
  try {
    for (const item of designItems) {
      await addDoc(collection(db, "designItems"), item);
    }
    console.log("✅ All design items uploaded to Firestore.");
  } catch (err) {
    console.error("❌ Failed to seed design items:", err);
  }
};
