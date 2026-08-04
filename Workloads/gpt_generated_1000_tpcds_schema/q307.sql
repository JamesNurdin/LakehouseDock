WITH
  /* Store sales filtered by Texas stores */
  store_tx AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_item_sk,
      SUM(ss.ss_net_profit) AS profit
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    WHERE s.s_state = 'TX'
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
  ),
  /* Store sales filtered to business‑hour transactions */
  store_business_hours AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_item_sk,
      SUM(ss.ss_net_profit) AS profit
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
  ),
  /* Intersection of the two profit result sets (same store‑item rows) */
  intersect_profit AS (
    SELECT ss_store_sk, ss_item_sk, profit
    FROM store_tx
    INTERSECT
    SELECT ss_store_sk, ss_item_sk, profit
    FROM store_business_hours
  ),
  /* Aggregated return amount per store‑item */
  returns_agg AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_item_sk,
      SUM(sr.sr_return_amt) AS return_amt
    FROM tpcds.store_sales ss
    JOIN tpcds.store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    WHERE sr.sr_return_quantity > 0
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
  ),
  /* Union of profit rows (from the intersect) with return rows, tagging the metric */
  unified AS (
    SELECT
      ss_store_sk,
      ss_item_sk,
      profit AS metric,
      'profit' AS metric_type
    FROM intersect_profit
    UNION
    SELECT
      ss_store_sk,
      ss_item_sk,
      return_amt AS metric,
      'return' AS metric_type
    FROM returns_agg
  )
SELECT
  ss_store_sk,
  ss_item_sk,
  metric_type,
  SUM(metric) AS total_metric
FROM unified
GROUP BY ROLLUP (ss_store_sk, ss_item_sk, metric_type)
ORDER BY ss_store_sk, ss_item_sk, metric_type
