// // pages/SeedPage.tsx
import { useEffect } from "react";
import { seedDesignItems } from "@/lib/seedDesignitems";

export const SeedPage = () => {
  // useEffect(() => {
  //   seedDesignItems();
  // }, []);

  return (
    <div className="text-center p-8 text-green-700">
      Uploading design services...
    </div>
  );
};
