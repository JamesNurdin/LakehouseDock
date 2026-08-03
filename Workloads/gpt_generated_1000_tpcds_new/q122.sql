WITH cr_agg AS (
   SELECT
       ca.ca_city AS city,
       i.i_category AS category,
       regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_cnt
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2001
     AND ca.ca_state LIKE 'A%'
     AND regexp_like(i.i_item_desc, '(?i)steel|plastic')
   GROUP BY ca.ca_city, i.i_category, regexp_extract(i.i_item_desc, '(\\w+)', 1)
),
wr_agg AS (
   SELECT
       ca.ca_city AS city,
       i.i_category AS category,
       regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word,
       SUM(wr.wr_return_amt) AS total_return_amount,
       COUNT(*) AS return_cnt
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2001
     AND ca.ca_state LIKE 'A%'
     AND regexp_like(i.i_item_desc, '(?i)steel|plastic')
   GROUP BY ca.ca_city, i.i_category, regexp_extract(i.i_item_desc, '(\\w+)', 1)
)
SELECT
   COALESCE(cr_agg.city, wr_agg.city) AS city,
   COALESCE(cr_agg.category, wr_agg.category) AS category,
   COALESCE(cr_agg.first_word, wr_agg.first_word) AS first_word,
   COALESCE(cr_agg.total_return_amount, 0) AS catalog_return_total,
   COALESCE(wr_agg.total_return_amount, 0) AS web_return_total,
   COALESCE(cr_agg.return_cnt, 0) AS catalog_return_cnt,
   COALESCE(wr_agg.return_cnt, 0) AS web_return_cnt,
   concat(COALESCE(cr_agg.city, wr_agg.city), '-', COALESCE(cr_agg.category, wr_agg.category)) AS city_category_key
FROM cr_agg
FULL OUTER JOIN wr_agg
  ON cr_agg.city = wr_agg.city
 AND cr_agg.category = wr_agg.category
 AND cr_agg.first_word = wr_agg.first_word
ORDER BY (catalog_return_total + web_return_total) DESC
LIMIT 100
