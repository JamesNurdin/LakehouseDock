WITH returns_agg AS (
   SELECT
       d.d_date AS event_date,
       'Return' AS event_type,
       cp.cp_type AS category,
       SUM(cr.cr_return_amount) AS total_amount,
       SUM(cr.cr_return_quantity) AS total_units
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_date, cp.cp_type
),
sales_agg AS (
   SELECT
       d.d_date AS event_date,
       'Sale' AS event_type,
       p.p_promo_name AS category,
       SUM(ss.ss_ext_sales_price) AS total_amount,
       SUM(ss.ss_quantity) AS total_units
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_date, p.p_promo_name
),
combined AS (
   SELECT * FROM returns_agg
   UNION ALL
   SELECT * FROM sales_agg
)
SELECT
   event_date,
   event_type,
   category,
   total_amount,
   total_units,
   CASE WHEN total_amount > 10000 THEN 'High' ELSE 'Low' END AS amount_level,
   SUM(total_amount) OVER (PARTITION BY category) AS total_amount_by_category,
   ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_amount DESC) AS rank_in_category
FROM combined
ORDER BY total_amount_by_category DESC, event_date
LIMIT 100
