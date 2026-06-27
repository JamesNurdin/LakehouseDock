/*
  Analytical query: For the top 5 stores by total in‑store revenue, show each product
  category's in‑store revenue, the overall web revenue for that category, the store's
  share of total (store + web) revenue for the category, the store's total revenue,
  and the average product rating of items sold in the store.
*/
WITH store_revenue AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name AS category_name,
        SUM(ss.ss_quantity * i.i_price) AS store_category_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
store_total AS (
    SELECT
        ss_store_id,
        SUM(store_category_revenue) AS store_total_revenue
    FROM store_revenue
    GROUP BY ss_store_id
),
store_ranked AS (
    SELECT
        ss_store_id,
        store_total_revenue,
        ROW_NUMBER() OVER (ORDER BY store_total_revenue DESC) AS store_rank
    FROM store_total
),
store_ratings AS (
    SELECT
        ss.ss_store_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
),
web_category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name AS category_name,
        SUM(ws.ws_quantity * i.i_price) AS web_category_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_name,
    sr.category_name,
    sr.store_category_revenue,
    wc.web_category_revenue,
    (sr.store_category_revenue / (sr.store_category_revenue + wc.web_category_revenue)) * 100 AS store_share_pct,
    sr_total.store_total_revenue,
    sr_avg.avg_rating
FROM store_revenue sr
JOIN store_ranked sr_total ON sr.ss_store_id = sr_total.ss_store_id
JOIN store_ratings sr_avg ON sr.ss_store_id = sr_avg.ss_store_id
JOIN web_category_sales wc ON sr.i_category_id = wc.i_category_id
JOIN stores s ON sr.ss_store_id = s.s_store_id
WHERE sr_total.store_rank <= 5
ORDER BY sr_total.store_total_revenue DESC, store_share_pct DESC
