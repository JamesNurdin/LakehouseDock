WITH store_sales_agg AS (
    SELECT
        'Store' AS sales_source,
        s.s_state AS region,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 20000 THEN 'High' ELSE 'Medium' END AS sales_category
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_shift LIKE 'second%'
      AND EXISTS (
          SELECT 1
          FROM income_band ib
          WHERE hd.hd_income_band_sk = ib.ib_income_band_sk
            AND ib.ib_lower_bound >= 50000
      )
    GROUP BY s.s_state
),
web_sales_agg AS (
    SELECT
        'Web' AS sales_source,
        ca.ca_state AS region,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 20000 THEN 'High' ELSE 'Medium' END AS sales_category
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_shift LIKE 'first%'
      AND hd.hd_income_band_sk IN (
          SELECT ib.ib_income_band_sk
          FROM income_band ib
          WHERE ib.ib_lower_bound >= 50000
      )
    GROUP BY ca.ca_state
)
SELECT sales_source, region, total_sales, sales_category
FROM store_sales_agg
UNION ALL
SELECT sales_source, region, total_sales, sales_category
FROM web_sales_agg
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
