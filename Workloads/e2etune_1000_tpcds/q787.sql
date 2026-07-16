WITH cs AS (
  SELECT
    t.t_hour,
    hd.hd_income_band_sk,
    cs.cs_net_profit,
    cs.cs_net_paid,
    cs.cs_ext_discount_amt,
    cs.cs_bill_customer_sk AS cust_sk
  FROM catalog_sales cs
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
    AND t.t_hour BETWEEN 9 AND 17
    AND hd.hd_income_band_sk IN (1, 2, 3)
),
ws AS (
  SELECT
    t.t_hour,
    hd.hd_income_band_sk,
    ws.ws_net_profit,
    ws.ws_net_paid,
    ws.ws_ext_discount_amt,
    ws.ws_bill_customer_sk AS cust_sk
  FROM web_sales ws
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
    AND t.t_hour BETWEEN 9 AND 17
    AND w.web_country = 'United States'
    AND hd.hd_income_band_sk IN (1, 2, 3)
)
SELECT
  channel,
  t_hour,
  hd_income_band_sk,
  SUM(total_net_profit) AS total_net_profit,
  SUM(total_net_paid) AS total_net_paid,
  AVG(total_discount) AS avg_discount,
  COUNT(DISTINCT cust_sk) AS distinct_customers
FROM (
  SELECT
    'Catalog' AS channel,
    t_hour,
    hd_income_band_sk,
    cs_net_profit AS total_net_profit,
    cs_net_paid AS total_net_paid,
    cs_ext_discount_amt AS total_discount,
    cust_sk
  FROM cs
  UNION ALL
  SELECT
    'Web' AS channel,
    t_hour,
    hd_income_band_sk,
    ws_net_profit AS total_net_profit,
    ws_net_paid AS total_net_paid,
    ws_ext_discount_amt AS total_discount,
    cust_sk
  FROM ws
) combined
GROUP BY channel, t_hour, hd_income_band_sk
HAVING SUM(total_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 20
