WITH
  filtered_sales AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_addr_sk,
      ss.ss_ext_sales_price,
      i.i_brand,
      i.i_item_desc,
      i.i_product_name,
      ca.ca_city,
      d.d_date,
      d.d_year,
      regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS digit_code,
      substring(ca.ca_city, 1, 3) AS city_prefix
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '[A-Za-z]+[0-9]{3}[A-Za-z]*')
      AND ca.ca_city LIKE '%York%'
      AND p.p_promo_name LIKE '%Clearance%'
  ),
  daily_brand_sales AS (
    SELECT
      i_brand,
      city_prefix,
      d_date,
      d_year,
      sum(ss_ext_sales_price) AS daily_sales,
      avg(ss_ext_sales_price) AS avg_sales_price
    FROM filtered_sales
    GROUP BY i_brand, city_prefix, d_date, d_year
  )
SELECT
  i_brand,
  city_prefix,
  d_year,
  d_date,
  daily_sales,
  avg_sales_price,
  sum(daily_sales) OVER (PARTITION BY i_brand ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
  concat(i_brand, '_', city_prefix) AS brand_city_key
FROM daily_brand_sales
ORDER BY i_brand, d_date DESC
LIMIT 100
