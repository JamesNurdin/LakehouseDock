WITH promo_agg AS (
   SELECT p_start_date_sk AS date_sk,
          COUNT(*) AS promo_cnt,
          SUM(p_cost) AS total_promo_cost
   FROM promotion
   GROUP BY p_start_date_sk
),
inventory_agg AS (
   SELECT inv_date_sk AS date_sk,
          SUM(inv_quantity_on_hand) AS total_inventory_qty,
          COUNT(DISTINCT inv_item_sk) AS distinct_items
   FROM inventory
   GROUP BY inv_date_sk
),
web_access_agg AS (
   SELECT wp_access_date_sk AS date_sk,
          COUNT(*) AS total_page_accesses
   FROM web_page
   GROUP BY wp_access_date_sk
),
web_creation_agg AS (
   SELECT wp_creation_date_sk AS date_sk,
          COUNT(*) AS total_page_creations
   FROM web_page
   GROUP BY wp_creation_date_sk
),
store_closed_agg AS (
   SELECT s_closed_date_sk AS date_sk,
          COUNT(*) AS stores_closed
   FROM store
   WHERE s_closed_date_sk IS NOT NULL
   GROUP BY s_closed_date_sk
)
SELECT d.d_date,
       d.d_year,
       d.d_month_seq,
       COALESCE(p.promo_cnt, 0) AS promo_cnt,
       COALESCE(p.total_promo_cost, 0) AS total_promo_cost,
       COALESCE(i.total_inventory_qty, 0) AS total_inventory_qty,
       COALESCE(i.distinct_items, 0) AS distinct_items,
       COALESCE(wa.total_page_accesses, 0) AS total_page_accesses,
       COALESCE(wc.total_page_creations, 0) AS total_page_creations,
       COALESCE(s.stores_closed, 0) AS stores_closed,
       SUM(COALESCE(p.total_promo_cost, 0)) OVER (ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_promo_cost
FROM date_dim d
LEFT JOIN promo_agg p ON d.d_date_sk = p.date_sk
LEFT JOIN inventory_agg i ON d.d_date_sk = i.date_sk
LEFT JOIN web_access_agg wa ON d.d_date_sk = wa.date_sk
LEFT JOIN web_creation_agg wc ON d.d_date_sk = wc.date_sk
LEFT JOIN store_closed_agg s ON d.d_date_sk = s.date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND d.d_weekend = 'N'
  AND d.d_holiday = 'N'
ORDER BY d.d_date DESC
LIMIT 200
