WITH item_sentiment AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
sales_combined AS (
    SELECT ss.ss_store_id AS store_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_ts AS ts
    FROM store_sales ss
    UNION ALL
    SELECT NULL AS store_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           ws.ws_ts AS ts
    FROM web_sales ws
)
SELECT COALESCE(st.s_store_name, 'Online') AS store_name,
       i.i_category AS category,
       SUM(sc.quantity) AS total_quantity,
       SUM(sc.quantity * i.i_price) AS total_revenue,
       AVG(isent.avg_sentiment) AS avg_item_sentiment
FROM sales_combined sc
JOIN items i
  ON sc.item_id = i.i_item_id
LEFT JOIN item_sentiment isent
  ON i.i_item_id = isent.pr_item_id
LEFT JOIN stores st
  ON sc.store_id = st.s_store_id
GROUP BY COALESCE(st.s_store_name, 'Online'), i.i_category
ORDER BY total_revenue DESC
LIMIT 20
