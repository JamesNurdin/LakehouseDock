WITH catalog_daily AS (
    SELECT d.d_date AS sale_date,
           sm.sm_code AS mode,
           SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND sm.sm_code = 'AIR'
    GROUP BY d.d_date, sm.sm_code
),
store_daily AS (
    SELECT d.d_date AS sale_date,
           p.p_promo_name AS mode,
           SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND p.p_channel_email = 'Y'
    GROUP BY d.d_date, p.p_promo_name
)
SELECT sale_date, mode, total_sales FROM catalog_daily
UNION ALL
SELECT sale_date, mode, total_sales FROM store_daily
LIMIT 100
