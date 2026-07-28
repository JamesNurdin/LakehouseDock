WITH filtered_sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_sales_price,
    i.i_item_desc,
    i.i_brand,
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    ca.ca_street_name
  FROM catalog_sales cs
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE regexp_like(i.i_item_desc, '(?i)red')
    AND ca.ca_street_name LIKE 'Main%'
)

SELECT
  d_year,
  d_month_seq,
  COUNT(DISTINCT cs_order_number) AS orders,
  SUM(cs_net_paid) AS total_net_paid,
  SUM(cs_net_profit) AS total_net_profit,
  AVG(cs_sales_price) AS avg_sales_price,
  CONCAT(substr(city_prefix, 1, 3), '-', substr(i_brand, 1, 2)) AS segment_code,
  captured_color
FROM (
  SELECT
    cs_order_number,
    cs_net_paid,
    cs_net_profit,
    cs_sales_price,
    i_item_desc,
    i_brand,
    d_year,
    d_month_seq,
    substr(ca_city, 1, 3) AS city_prefix,
    regexp_extract(i_item_desc, '(?i)(Red|Blue|Green)', 1) AS captured_color
  FROM filtered_sales
) sub
GROUP BY
  d_year,
  d_month_seq,
  captured_color,
  CONCAT(substr(city_prefix, 1, 3), '-', substr(i_brand, 1, 2))
ORDER BY d_year, d_month_seq
