WITH catalog_agg AS (
    SELECT
        d.d_year AS year,
        'Catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        cs.cs_call_center_sk
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND cc.cc_gmt_offset > -5
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
          WHERE hd.hd_demo_sk = cs.cs_bill_hdemo_sk
            AND ib.ib_upper_bound > 50000
      )
    GROUP BY d.d_year, cs.cs_call_center_sk
    HAVING SUM(cs.cs_ext_sales_price) > 10000
),
web_agg AS (
    SELECT
        d.d_year AS year,
        'Web' AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ws.ws_web_site_sk
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
      AND w.web_tax_percentage < 5
      AND NOT EXISTS (
          SELECT 1
          FROM household_demographics hd2
          JOIN income_band ib2
            ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
          WHERE hd2.hd_demo_sk = ws.ws_bill_hdemo_sk
            AND ib2.ib_lower_bound = 0
      )
    GROUP BY d.d_year, ws.ws_web_site_sk
    HAVING SUM(ws.ws_ext_sales_price) > 10000
)
SELECT u.year,
       u.channel,
       u.total_sales
FROM (
    SELECT year, channel, total_sales FROM catalog_agg
    UNION ALL
    SELECT year, channel, total_sales FROM web_agg
) u
WHERE NOT EXISTS (
    SELECT 1
    FROM call_center cc
    JOIN date_dim d2
        ON cc.cc_closed_date_sk = d2.d_date_sk
    WHERE d2.d_year = u.year
)
ORDER BY u.total_sales DESC
LIMIT 100
