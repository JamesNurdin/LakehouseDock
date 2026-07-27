WITH store_sales_agg AS (
    SELECT
        'store' AS sales_channel,
        d.d_year AS d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_geography_class = 'Unknown'
      AND d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          WHERE hd.hd_demo_sk = ss.ss_hdemo_sk
            AND hd.hd_vehicle_count > 2
      )
    GROUP BY d.d_year
),
web_sales_agg AS (
    SELECT
        'web' AS sales_channel,
        d.d_year AS d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_manager = 'John Ward'
      AND d.d_year = 2001
      AND ws.ws_bill_hdemo_sk IN (
          SELECT hd_demo_sk
          FROM household_demographics
          WHERE hd_income_band_sk = 3
      )
    GROUP BY d.d_year
)
SELECT sales_channel, d_year, total_sales
FROM store_sales_agg
UNION ALL
SELECT sales_channel, d_year, total_sales
FROM web_sales_agg
ORDER BY sales_channel, d_year
