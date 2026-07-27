WITH sales_returns AS (
  SELECT
    ws.ws_order_number,
    ws.ws_web_site_sk,
    ws.ws_ext_sales_price AS sales_price,
    ws.ws_net_profit,
    cr.cr_return_amount,
    cr.cr_net_loss,
    td.t_hour,
    td.t_minute,
    wsit.web_name,
    wsit.web_company_name,
    ca.ca_state,
    hd.hd_buy_potential,
    CASE WHEN cr.cr_return_amount > 0 THEN 'RETURN' ELSE 'SALE' END AS transaction_type,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  LEFT JOIN catalog_returns cr ON ws.ws_order_number = cr.cr_order_number
  LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  LEFT JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE wsit.web_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
    AND td.t_hour BETWEEN 8 AND 20
    AND ws.ws_ext_discount_amt > 1000
    AND ca.ca_state = 'CA'
    AND hd.hd_buy_potential = 'HIGH'
)
SELECT
  transaction_type,
  web_name,
  web_company_name,
  ca_state,
  hd_buy_potential,
  t_hour,
  SUM(sales_price) AS total_sales,
  SUM(ws_net_profit) AS total_profit,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(cr_net_loss) AS total_return_loss,
  CASE WHEN SUM(ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_indicator,
  RANK() OVER (PARTITION BY web_name ORDER BY SUM(ws_net_profit) DESC) AS profit_rank_by_site
FROM sales_returns
GROUP BY GROUPING SETS (
  (transaction_type, web_name, web_company_name, ca_state, hd_buy_potential, t_hour),
  (transaction_type, web_name, web_company_name, ca_state, hd_buy_potential),
  (transaction_type, web_name, web_company_name),
  (transaction_type, web_name),
  (transaction_type)
)
ORDER BY profit_rank_by_site
LIMIT 100
