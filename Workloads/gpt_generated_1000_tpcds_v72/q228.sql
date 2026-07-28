WITH sales_agg AS (
  SELECT
    c.c_customer_sk,
    d.d_year,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS web_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN web_sales ws
    ON cs.cs_item_sk = ws.ws_item_sk
   AND cs.cs_order_number = ws.ws_order_number
   AND ws.ws_sold_date_sk = d.d_date_sk
  GROUP BY
    c.c_customer_sk,
    d.d_year
)
SELECT DISTINCT
  sa.d_year AS d_year,
  hd2.hd_buy_potential,
  SUM(sa.catalog_profit) AS total_catalog_profit,
  SUM(sa.web_profit) AS total_web_profit,
  SUM(sr.sr_return_amt) AS total_store_return_amt,
  SUM(wr.wr_return_amt) AS total_web_return_amt,
  (
    SELECT AVG(cs2.cs_ext_sales_price)
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = sa.d_year
  ) AS avg_catalog_sales_price_year
FROM sales_agg sa
JOIN customer cust2
  ON sa.c_customer_sk = cust2.c_customer_sk
JOIN household_demographics hd2
  ON cust2.c_current_hdemo_sk = hd2.hd_demo_sk
JOIN store_returns sr
  ON sr.sr_customer_sk = cust2.c_customer_sk
JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN web_returns wr
  ON wr.wr_refunded_customer_sk = cust2.c_customer_sk
JOIN web_sales ws2
  ON wr.wr_order_number = ws2.ws_order_number
JOIN web_page wp
  ON ws2.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr_chk
    WHERE sr_chk.sr_customer_sk = cust2.c_customer_sk
      AND sr_chk.sr_return_amt > 500
)
GROUP BY
  sa.d_year,
  hd2.hd_buy_potential
HAVING
  SUM(sa.catalog_profit) + SUM(sa.web_profit) > 10000
ORDER BY
  total_catalog_profit DESC
LIMIT 100
