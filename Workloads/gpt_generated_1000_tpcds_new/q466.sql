WITH
  ss_pre AS (
    SELECT
      s.s_store_name AS store_name,
      d.d_year AS year,
      CASE WHEN ss.ss_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
      (
        SELECT COUNT(*)
        FROM catalog_sales cs
        WHERE cs.cs_bill_customer_sk = ss.ss_customer_sk
      ) AS cust_total_catalog_orders,
      qty_price AS array_value,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_net_profit DESC) AS rn
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN UNNEST(ARRAY[CAST(ss.ss_quantity AS double), ss.ss_sales_price]) AS t (qty_price)
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
  ),
  ws_pre AS (
    SELECT
      w.web_name AS store_name,
      d.d_year AS year,
      CASE WHEN ws.ws_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
      (
        SELECT COUNT(*)
        FROM catalog_sales cs
        WHERE cs.cs_bill_customer_sk = ws.ws_bill_customer_sk
      ) AS cust_total_catalog_orders,
      qty_price AS array_value,
      ROW_NUMBER() OVER (PARTITION BY w.web_name ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN UNNEST(ARRAY[CAST(ws.ws_quantity AS double), ws.ws_sales_price]) AS t (qty_price)
    WHERE d.d_year = 2001
      AND w.web_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
  )
SELECT
  store_name,
  year,
  profit_level,
  cust_total_catalog_orders,
  array_value,
  rn
FROM (
  SELECT store_name, year, profit_level, cust_total_catalog_orders, array_value, rn
  FROM ss_pre
  WHERE rn <= 5
  UNION
  SELECT store_name, year, profit_level, cust_total_catalog_orders, array_value, rn
  FROM ws_pre
  WHERE rn <= 5
) AS combined
ORDER BY profit_level DESC, rn
LIMIT 100
