(ns frontend.components
  (:require [reagent.core :as r]))

(defonce todos (r/atom []))
(defonce new-title (r/atom ""))

(defn fetch-todos! []
  (-> (js/fetch "/api/todos")
      (.then (fn [res] (.json res)))
      (.then (fn [data] (reset! todos (clj->js data))))))

(defn create-todo! []
  (let [title @new-title]
    (when (and title (not (clojure.string/blank? title)))
      (-> (js/fetch "/api/todos"
                    (clj->js {:method "POST"
                              :headers {"Content-Type" "application/json"}
                              :body (js/JSON.stringify (clj->js {:title title}))}))
          (.then (fn [_] (reset! new-title "") (fetch-todos!)))))))

(defn toggle-todo! [id done]
  (-> (js/fetch (str "/api/todos/" id)
                (clj->js {:method "PUT"
                          :headers {"Content-Type" "application/json"}
                          :body (js/JSON.stringify (clj->js {:done (not done)}))}))
      (.then (fn [_] (fetch-todos!)))))

(defn delete-todo! [id]
  (-> (js/fetch (str "/api/todos/" id)
                (clj->js {:method "DELETE"}))
      (.then (fn [_] (fetch-todos!)))))

(defn todo-item [t]
  (let [id (.-id t)
        title (.-title t)
        done (.-done t)]
    [:li
     [:input {:type "checkbox" :checked done :on-change #(toggle-todo! id done)}]
     [:span {:style {:text-decoration (when done "line-through") :margin-left "8px"}} title]
     [:button {:on-click #(delete-todo! id) :style {:margin-left "12px"}} "Delete"]]))

(defn app []
  (r/create-class
   {:component-did-mount fetch-todos!
    :reagent-render
    (fn []
      [:div
       [:h2 "Todo List (Clojure + Reagent)"]
       [:div
        [:input {:placeholder "New todo" :value @new-title :on-change #(reset! new-title (.. % -target -value))}]
        [:button {:on-click create-todo!} "Add"]]
       [:ul (for [t @todos] ^{:key (.-id t)} [todo-item t])]])}))
