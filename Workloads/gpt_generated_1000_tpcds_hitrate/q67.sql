WITH sales_data AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    i.i_item_id AS item_id,
    CAST('sales' AS varchar) AS metric_type,
    SUM(ss.ss_net_paid) AS metric_amount,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2451912 AND 2451915
  GROUP BY s.s_store_id, s.s_store_name, i.i_item_id
),
returns_data AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    i.i_item_id AS item_id,
    CAST('returns' AS varchar) AS metric_type,
    SUM(sr.sr_refunded_cash) AS metric_amount,
    CASE WHEN SUM(sr.sr_refunded_cash) > 100 THEN 'HIGH' ELSE 'LOW' END AS profit_flag
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2451912 AND 2451915
  GROUP BY s.s_store_id, s.s_store_name, i.i_item_id
)
SELECT
  combined.store_id,
  combined.store_name,
  combined.item_id,
  combined.metric_type,
  combined.metric_amount,
  combined.profit_flag
FROM (
  SELECT store_id, store_name, item_id, metric_type, metric_amount, profit_flag FROM sales_data
  UNION ALL
  SELECT store_id, store_name, item_id, metric_type, metric_amount, profit_flag FROM returns_data
) AS combined
ORDER BY combined.metric_amount DESC
LIMIT 100
