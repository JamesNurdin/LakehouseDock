WITH aggregated AS (
  SELECT
    bd.cd_gender AS billing_gender,
    sd.cd_gender AS shipping_gender,
    bd.cd_marital_status AS billing_marital_status,
    sd.cd_marital_status AS shipping_marital_status,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    (SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) AS profit_margin
  FROM web_sales ws
  JOIN customer_demographics bd
    ON ws.ws_bill_cdemo_sk = bd.cd_demo_sk
  JOIN customer_demographics sd
    ON ws.ws_ship_cdemo_sk = sd.cd_demo_sk
  WHERE bd.cd_gender = 'F'
    AND bd.cd_credit_rating = 'Good'
    AND bd.cd_purchase_estimate >= 1500
    AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2450830
  GROUP BY bd.cd_gender, sd.cd_gender, bd.cd_marital_status, sd.cd_marital_status
  HAVING SUM(ws.ws_ext_sales_price) > 10000
)
SELECT
  *,
  RANK() OVER (ORDER BY profit_margin DESC) AS profit_rank
FROM aggregated
ORDER BY profit_rank
LIMIT 10
