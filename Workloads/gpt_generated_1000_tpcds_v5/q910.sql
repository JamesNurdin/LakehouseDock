WITH closed_inventory AS (
   SELECT
       s.s_store_name AS store_name,
       d.d_month_seq AS month_seq,
       SUM(i.inv_quantity_on_hand) AS total_qty,
       'closed_2000' AS source_label
   FROM inventory i
   JOIN date_dim d
       ON i.inv_date_sk = d.d_date_sk
   JOIN store s
       ON s.s_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
   GROUP BY s.s_store_name, d.d_month_seq
),
year2001_inventory AS (
   SELECT
       CAST(NULL AS varchar) AS store_name,
       d.d_month_seq AS month_seq,
       SUM(i.inv_quantity_on_hand) AS total_qty,
       'all_2001' AS source_label
   FROM inventory i
   JOIN date_dim d
       ON i.inv_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_month_seq
)
SELECT *
FROM closed_inventory
UNION ALL
SELECT *
FROM year2001_inventory
ORDER BY month_seq, source_label
LIMIT 100
