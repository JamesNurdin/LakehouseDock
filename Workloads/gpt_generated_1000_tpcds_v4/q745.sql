WITH sales_agg AS (
  SELECT
    d.d_year,
    d.d_quarter_seq,
    c.c_customer_sk,
    SUM(ss.ss_net_profit) AS store_profit,
    0.0 AS web_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND d.d_quarter_seq IN (4, 8)
    AND c.c_preferred_cust_flag = 'Y'
    AND ca.ca_state = 'CA'
    AND c.c_customer_sk IN (
      SELECT c2.c_customer_sk
      FROM customer c2
      WHERE c2.c_birth_country = 'United States'
    )
  GROUP BY d.d_year, d.d_quarter_seq, c.c_customer_sk

  UNION ALL

  SELECT
    d.d_year,
    d.d_quarter_seq,
    c.c_customer_sk,
    0.0 AS store_profit,
    SUM(ws.ws_net_profit) AS web_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2001
    AND d.d_quarter_seq IN (4, 8)
    AND sm.sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
    AND c.c_preferred_cust_flag = 'Y'
    AND ca.ca_state = 'CA'
    AND c.c_customer_sk IN (
      SELECT c2.c_customer_sk
      FROM customer c2
      WHERE c2.c_birth_country = 'United States'
    )
  GROUP BY d.d_year, d.d_quarter_seq, c.c_customer_sk
)
SELECT
  year,
  quarter_seq,
  AVG(total_profit) AS avg_profit_per_customer
FROM (
  SELECT
    d_year AS year,
    d_quarter_seq AS quarter_seq,
    c_customer_sk,
    store_profit + web_profit AS total_profit
  FROM sales_agg
) t
GROUP BY year, quarter_seq
HAVING AVG(total_profit) > 1000
ORDER BY avg_profit_per_customer DESC
LIMIT 100
