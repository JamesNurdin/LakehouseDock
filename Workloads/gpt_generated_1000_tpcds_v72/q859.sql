WITH max_income AS (
  SELECT MAX(ib_upper_bound) AS max_upper FROM tpcds.income_band
)
SELECT
  w.web_mkt_desc,
  w.web_market_manager,
  COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
  SUM(ws.ws_net_profit) / COUNT(DISTINCT ws.ws_order_number) AS avg_net_profit,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  AVG(ib.ib_lower_bound) AS avg_income_lower,
  (SELECT MAX(ib2.ib_upper_bound) FROM tpcds.income_band ib2) AS max_income_upper,
  REGEXP_EXTRACT(w.web_mkt_desc, '(\\w+)') AS first_word,
  CONCAT(w.web_name, ' - ', w.web_city) AS site_full_name
FROM tpcds.web_sales ws
JOIN tpcds.web_site w
  ON ws.ws_web_site_sk = w.web_site_sk
JOIN tpcds.date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN tpcds.household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE d.d_year = 2001
  AND regexp_like(lower(w.web_mkt_desc), 'political')
  AND w.web_name LIKE 'W%'
  AND EXISTS (
    SELECT 1
    FROM tpcds.customer c2
    WHERE c2.c_current_hdemo_sk = hd.hd_demo_sk
      AND c2.c_preferred_cust_flag = 'Y'
  )
GROUP BY
  w.web_mkt_desc,
  w.web_market_manager,
  w.web_name,
  w.web_city
ORDER BY avg_net_profit DESC
LIMIT 100
