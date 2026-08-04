WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_quantity,
    cs.cs_net_profit,
    d.d_year,
    d.d_date,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    wp.wp_web_page_id,
    wp.wp_image_count,
    wp.wp_rec_start_date,
    SPLIT(wp.wp_url, '/') AS url_parts
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
    AND hd.hd_income_band_sk IN (6, 7, 9, 19)
    AND wp.wp_image_count >= 2
    AND cs.cs_ext_sales_price > 1000
    AND d.d_date >= DATE '1999-01-01'
    AND EXISTS (
      SELECT 1
      FROM household_demographics hd2
      WHERE hd2.hd_income_band_sk = hd.hd_income_band_sk
        AND hd2.hd_vehicle_count > 0
    )
),
exploded AS (
  SELECT
    b.*, 
    url_part
  FROM base b
  CROSS JOIN UNNEST(b.url_parts) AS t(url_part)
),
sales_agg AS (
  SELECT
    d_year,
    hd_income_band_sk,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs_order_number) AS orders_cnt
  FROM exploded
  GROUP BY d_year, hd_income_band_sk
  HAVING SUM(cs_ext_sales_price) > 5000
),
order_numbers AS (
  SELECT cs.cs_order_number
  FROM catalog_sales cs
  WHERE cs.cs_ext_sales_price > 2000
),
web_orders AS (
  SELECT cs.cs_order_number
  FROM catalog_sales cs
  JOIN web_page wp ON wp.wp_creation_date_sk = cs.cs_sold_date_sk
  WHERE wp.wp_image_count = 3
)
SELECT intersected.cs_order_number
FROM (
  SELECT onum.cs_order_number
  FROM order_numbers onum
  INTERSECT
  SELECT won.cs_order_number
  FROM web_orders won
) AS intersected
ORDER BY intersected.cs_order_number
OFFSET 0 LIMIT 100
