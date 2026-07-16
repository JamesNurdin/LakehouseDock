WITH filtered_sales AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    ws.ws_quantity,
    d.d_year,
    d.d_quarter_name,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_credit_rating AS ship_credit_rating
  FROM web_sales ws
  INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  INNER JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  INNER JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  INNER JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  WHERE d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND cd_bill.cd_purchase_estimate >= 1500
    AND cd_ship.cd_purchase_estimate >= 1500
    AND cd_bill.cd_credit_rating IN ('Good', 'Low Risk')
    AND cd_ship.cd_credit_rating IN ('Good', 'Low Risk')
)
SELECT
  d_year,
  d_quarter_name,
  bill_gender,
  ship_credit_rating,
  SUM(ws_net_profit) AS total_profit,
  AVG(ws_ext_discount_amt) AS avg_discount,
  COUNT(DISTINCT ws_order_number) AS order_cnt,
  SUM(ws_quantity) AS total_quantity,
  SUM(ws_net_profit) / NULLIF(SUM(ws_quantity), 0) AS profit_per_item,
  RANK() OVER (PARTITION BY d_year ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM filtered_sales
GROUP BY d_year, d_quarter_name, bill_gender, ship_credit_rating
HAVING SUM(ws_net_profit) > 10000
ORDER BY profit_rank, total_profit DESC
LIMIT 100
