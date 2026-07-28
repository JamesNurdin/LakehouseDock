WITH filtered_sales AS (
  SELECT
    ss.ss_item_sk,
    ss.ss_store_sk,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    ss.ss_sold_date_sk
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    AND regexp_like(d.d_day_name, '^S')
)
SELECT
  i.i_item_id,
  i.i_product_name,
  s.s_store_name,
  SUM(f.ss_ext_sales_price) AS total_sales,
  SUM(f.ss_net_profit) AS total_profit,
  CASE WHEN SUM(f.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
  regexp_extract(i.i_item_desc, '(\\d+)', 1) AS first_number_in_desc,
  CASE
    WHEN i.i_container LIKE '%steel%' THEN 'Steel Container'
    WHEN i.i_container LIKE '%plastic%' THEN 'Plastic Container'
    ELSE 'Other'
  END AS container_type
FROM filtered_sales f
JOIN item i
  ON f.ss_item_sk = i.i_item_sk
JOIN store s
  ON f.ss_store_sk = s.s_store_sk
WHERE regexp_like(i.i_product_name, '\\d{4}')
GROUP BY
  i.i_item_id,
  i.i_product_name,
  s.s_store_name,
  i.i_item_desc,
  i.i_container
ORDER BY total_sales DESC
LIMIT 100
