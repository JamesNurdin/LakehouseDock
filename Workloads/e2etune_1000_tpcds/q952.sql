WITH ws_agg AS (
  SELECT
    ws.ws_warehouse_sk,
    w.w_state,
    w.w_country,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
    COUNT(*) AS sales_transactions
  FROM web_sales ws
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450900 AND 2451000
    AND ws.ws_sales_price > 0
  GROUP BY ws.ws_warehouse_sk, w.w_state, w.w_country
)
SELECT
  wa.w_state,
  wa.w_country,
  wa.total_net_profit,
  wa.avg_net_profit,
  wa.total_quantity,
  wa.distinct_customers,
  wa.sales_transactions,
  (SELECT SUM(sr_return_amt) FROM store_returns sr WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451000) AS total_return_amount,
  (SELECT SUM(sr_net_loss) FROM store_returns sr WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451000) AS total_net_loss,
  (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451000) AS total_returns,
  (SELECT COUNT(*) FROM catalog_page cp WHERE cp.cp_type = 'monthly') AS total_catalog_pages,
  (SELECT COUNT(DISTINCT cp_type) FROM catalog_page cp WHERE cp.cp_type = 'monthly') AS distinct_cp_types,
  RANK() OVER (ORDER BY wa.total_net_profit DESC) AS profit_rank
FROM ws_agg wa
WHERE wa.total_net_profit > 10000
ORDER BY profit_rank
LIMIT 20
