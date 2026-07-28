WITH promo_active AS (
    SELECT p_promo_sk, p_promo_name
    FROM promotion
    WHERE p_discount_active = 'Y'
)
SELECT year,
       month_seq,
       total_sales,
       sales_type,
       rn
FROM (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           'sold' AS sales_type,
           ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promo_active pa ON ws.ws_promo_sk = pa.p_promo_sk
    WHERE d.d_year IN (2001, 2002)
    GROUP BY GROUPING SETS ((d.d_year, d.d_month_seq), (d.d_year), ())
) sold_sales
UNION ALL
SELECT year,
       month_seq,
       total_sales,
       sales_type,
       rn
FROM (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           'shipped' AS sales_type,
           ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    LEFT JOIN promo_active pa ON ws.ws_promo_sk = pa.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY CUBE (d.d_year, d.d_month_seq)
) shipped_sales
LIMIT 100
