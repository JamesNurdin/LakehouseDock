WITH sales_data AS (
   SELECT i.i_item_id AS item_id,
          sm.sm_type AS ship_mode_type,
          'sales' AS metric_type,
          SUM(cs.cs_ext_sales_price) AS total_amount
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
   GROUP BY i.i_item_id, sm.sm_type
),
returns_data AS (
   SELECT i.i_item_id AS item_id,
          sm.sm_type AS ship_mode_type,
          'returns' AS metric_type,
          SUM(cr.cr_return_amount) AS total_amount
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE cr.cr_returned_date_sk BETWEEN 2450830 AND 2450840
   GROUP BY i.i_item_id, sm.sm_type
),
combined AS (
   SELECT * FROM sales_data
   UNION ALL
   SELECT * FROM returns_data
)
SELECT
    item_id,
    ship_mode_type,
    metric_type,
    total_amount,
    CASE WHEN total_amount > 1000 THEN 'high' ELSE 'low' END AS amount_category,
    ROW_NUMBER() OVER (PARTITION BY metric_type ORDER BY total_amount DESC) AS metric_rank
FROM combined
ORDER BY total_amount DESC
LIMIT 100
