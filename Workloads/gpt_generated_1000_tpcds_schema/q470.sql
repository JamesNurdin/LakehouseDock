WITH catalog_data AS (
  SELECT
    i.i_item_sk,
    i.i_category,
    d.d_year,
    SUM(cs.cs_ext_sales_price) AS sales_amount,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
  GROUP BY i.i_item_sk, i.i_category, d.d_year
  HAVING SUM(cs.cs_ext_sales_price) > 10000
),
store_data AS (
  SELECT
    i.i_item_sk,
    i.i_category,
    d.d_year,
    SUM(ss.ss_ext_sales_price) AS sales_amount,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
  GROUP BY i.i_item_sk, i.i_category, d.d_year
  HAVING SUM(ss.ss_ext_sales_price) > 10000
),
combined_sales AS (
  SELECT i_item_sk, i_category, d_year, sales_amount, sales_rank, 'catalog' AS src
  FROM catalog_data
  UNION ALL
  SELECT i_item_sk, i_category, d_year, sales_amount, sales_rank, 'store' AS src
  FROM store_data
),
excluded_items AS (
  SELECT i_item_sk
  FROM item
  WHERE i_color = 'Red'
)
SELECT
  cs.i_item_sk,
  cs.i_category,
  cs.d_year,
  cs.sales_amount,
  cs.sales_rank,
  cs.src,
  ca.ca_city,
  city_word
FROM combined_sales cs
JOIN catalog_sales csale ON cs.i_item_sk = csale.cs_item_sk
JOIN customer_address ca ON csale.cs_bill_addr_sk = ca.ca_address_sk
CROSS JOIN UNNEST(split(ca.ca_city, ' ')) AS t(city_word)
WHERE NOT EXISTS (SELECT 1 FROM excluded_items ei WHERE ei.i_item_sk = cs.i_item_sk)
EXCEPT
SELECT i_item_sk, i_category, d_year, sales_amount, sales_rank, src, ca_city, city_word
FROM (
  SELECT
    cs2.i_item_sk,
    cs2.i_category,
    cs2.d_year,
    cs2.sales_amount,
    cs2.sales_rank,
    cs2.src,
    ca2.ca_city,
    city_word2 AS city_word
  FROM combined_sales cs2
  JOIN catalog_sales csale2 ON cs2.i_item_sk = csale2.cs_item_sk
  JOIN customer_address ca2 ON csale2.cs_bill_addr_sk = ca2.ca_address_sk
  CROSS JOIN UNNEST(split(ca2.ca_city, ' ')) AS t2(city_word2)
  WHERE cs2.sales_amount < 15000
) low_sales
