(ns frontend.core
  (:require [reagent.core :as r]
            [frontend.components :refer [app]]))

(defn mount []
  (r/render [app]
            (.getElementById js/document "app")))

(defn init []
  (mount))
