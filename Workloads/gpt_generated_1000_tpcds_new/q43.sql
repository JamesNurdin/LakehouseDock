WITH item_filtered AS (
  SELECT i_item_sk, i_product_name, i_brand, i_class
  FROM item
  WHERE i_brand = 'Brand#35'
)
SELECT
  d.d_year,
  COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
  COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  REGEXP_EXTRACT(i.i_product_name, '([A-Za-z]+)', 1) AS first_word,
  CONCAT(i.i_brand, '-', i.i_class) AS brand_class,
  ca.ca_city
FROM store_sales ss
RIGHT OUTER JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
  AND i.i_brand = 'Brand#35'
  AND REGEXP_LIKE(i.i_product_name, 'Gold')
LEFT JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
  AND ss.ss_addr_sk IN (
        SELECT ca2.ca_address_sk
        FROM customer_address ca2
        WHERE ca2.ca_city LIKE 'A%'
      )
WHERE d.d_year = 2001
GROUP BY
  d.d_year,
  hd.hd_buy_potential,
  REGEXP_EXTRACT(i.i_product_name, '([A-Za-z]+)', 1),
  CONCAT(i.i_brand, '-', i.i_class),
  ca.ca_city
ORDER BY total_sales DESC
LIMIT 100
