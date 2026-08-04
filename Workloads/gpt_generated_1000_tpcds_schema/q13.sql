WITH
  item_desc AS (
    SELECT
      i_item_sk,
      i_item_desc,
      REGEXP_EXTRACT(i_item_desc, '(\\w+)') AS first_word,
      CASE WHEN REGEXP_LIKE(i_item_desc, '^.*[0-9]{3}.*$') THEN 'HasDigits' ELSE 'NoDigits' END AS digit_flag
    FROM item
    WHERE REGEXP_LIKE(i_item_desc, '.*(size|color).*')
  ),
  ss_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (5)
  )
SELECT
  s.s_store_name,
  d.d_year,
  COUNT(DISTINCT ss_sample.ss_ticket_number) AS num_transactions,
  SUM(ss_sample.ss_net_paid) AS total_net_paid,
  id.first_word,
  id.digit_flag
FROM ss_sample
JOIN store s ON ss_sample.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss_sample.ss_sold_date_sk = d.d_date_sk
JOIN item_desc id ON ss_sample.ss_item_sk = id.i_item_sk
WHERE s.s_store_name LIKE '%Store%'
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY s.s_store_name, d.d_year, id.first_word, id.digit_flag
ORDER BY total_net_paid DESC
LIMIT 100
