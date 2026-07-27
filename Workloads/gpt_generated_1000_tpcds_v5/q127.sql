WITH
  store_agg AS (
    SELECT
      d.d_year AS year,
      s.s_state AS state,
      CONCAT(s.s_store_name, ' - ', s.s_city) AS store_desc,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS txn_count,
      CASE
        WHEN SUM(ss.ss_ext_sales_price) < 10000 THEN 'Low'
        WHEN SUM(ss.ss_ext_sales_price) < 50000 THEN 'Medium'
        ELSE 'High'
      END AS sales_category,
      'store' AS channel
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE regexp_like(s.s_store_name, '^A.*')
      AND s.s_city LIKE '%York%'
      AND d.d_year = 2002
    GROUP BY d.d_year, s.s_state, s.s_store_name, s.s_city
  ),
  web_agg AS (
    SELECT
      d.d_year AS year,
      hd.hd_buy_potential AS state,
      CONCAT('Web - ', CAST(d.d_year AS varchar)) AS store_desc,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS txn_count,
      CASE
        WHEN SUM(ws.ws_ext_sales_price) < 10000 THEN 'Low'
        WHEN SUM(ws.ws_ext_sales_price) < 50000 THEN 'Medium'
        ELSE 'High'
      END AS sales_category,
      'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(hd.hd_buy_potential, '^.*[A-Z]$')
      AND d.d_year = 2002
      AND ws.ws_ext_sales_price > 0
    GROUP BY d.d_year, hd.hd_buy_potential, d.d_year
  )
SELECT
  year,
  state,
  store_desc,
  total_sales,
  txn_count,
  sales_category,
  channel
FROM store_agg
UNION ALL
SELECT
  year,
  state,
  store_desc,
  total_sales,
  txn_count,
  sales_category,
  channel
FROM web_agg
ORDER BY year DESC, total_sales DESC
