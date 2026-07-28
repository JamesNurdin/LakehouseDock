WITH
  returns_agg AS (
    SELECT
      r.sr_store_sk AS store_id,
      CAST('return' AS VARCHAR) AS metric_type,
      SUM(r.sr_return_amt_inc_tax) AS total_amount,
      COUNT(*) AS transaction_cnt
    FROM
      tpcds.store_returns r
      JOIN tpcds.store_sales s
        ON r.sr_item_sk = s.ss_item_sk
        AND r.sr_ticket_number = s.ss_ticket_number
    WHERE
      r.sr_return_amt_inc_tax > 500
    GROUP BY
      r.sr_store_sk
  ),
  sales_agg AS (
    SELECT
      s.ss_store_sk AS store_id,
      CAST('sales' AS VARCHAR) AS metric_type,
      SUM(s.ss_net_paid_inc_tax) AS total_amount,
      COUNT(*) AS transaction_cnt
    FROM
      tpcds.store_sales s
      JOIN tpcds.store_returns r
        ON s.ss_item_sk = r.sr_item_sk
        AND s.ss_ticket_number = r.sr_ticket_number
    WHERE
      s.ss_net_paid_inc_tax > 2000
    GROUP BY
      s.ss_store_sk
  )
SELECT
  store_id,
  metric_type,
  total_amount,
  transaction_cnt
FROM returns_agg
UNION ALL
SELECT
  store_id,
  metric_type,
  total_amount,
  transaction_cnt
FROM sales_agg
ORDER BY total_amount DESC
LIMIT 100
