WITH combined AS (
  SELECT
    i.i_category AS category,
    NULL AS ship_mode,
    SUM(ss.ss_ext_sales_price) AS sales_amount,
    SUM(ss.ss_ext_discount_amt) AS discount_amount,
    SUM(ss.ss_net_profit) AS net_profit,
    0 AS return_amount,
    0 AS fee_amount,
    COUNT(*) AS sales_transactions,
    0 AS return_transactions
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY i.i_category

  UNION ALL

  SELECT
    i.i_category AS category,
    sm.sm_type AS ship_mode,
    SUM(ws.ws_ext_sales_price) AS sales_amount,
    SUM(ws.ws_ext_discount_amt) AS discount_amount,
    SUM(ws.ws_net_profit) AS net_profit,
    0 AS return_amount,
    0 AS fee_amount,
    COUNT(*) AS sales_transactions,
    0 AS return_transactions
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
  GROUP BY i.i_category, sm.sm_type

  UNION ALL

  SELECT
    i.i_category AS category,
    NULL AS ship_mode,
    0 AS sales_amount,
    0 AS discount_amount,
    0 AS net_profit,
    SUM(sr.sr_return_amt_inc_tax) AS return_amount,
    SUM(sr.sr_fee) AS fee_amount,
    0 AS sales_transactions,
    COUNT(*) AS return_transactions
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY i.i_category

  UNION ALL

  SELECT
    i.i_category AS category,
    sm.sm_type AS ship_mode,
    0 AS sales_amount,
    0 AS discount_amount,
    0 AS net_profit,
    SUM(cr.cr_return_amt_inc_tax) AS return_amount,
    SUM(cr.cr_fee) AS fee_amount,
    0 AS sales_transactions,
    COUNT(*) AS return_transactions
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
  GROUP BY i.i_category, sm.sm_type
)
SELECT
  category,
  COALESCE(ship_mode, 'UNKNOWN') AS ship_mode,
  SUM(sales_amount) AS total_sales_amount,
  SUM(discount_amount) AS total_discount_amount,
  SUM(net_profit) AS total_net_profit,
  SUM(return_amount) AS total_return_amount,
  SUM(fee_amount) AS total_fee_amount,
  SUM(sales_transactions) AS total_sales_transactions,
  SUM(return_transactions) AS total_return_transactions,
  (SUM(sales_amount) - SUM(return_amount) - SUM(fee_amount)) AS net_profit_after_returns
FROM combined
GROUP BY category, ship_mode
HAVING SUM(sales_amount) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 50
