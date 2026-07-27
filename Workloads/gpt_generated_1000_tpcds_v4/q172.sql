WITH filtered_sales AS (
  SELECT
    s.s_store_name,
    concat(s.s_city, ', ', s.s_state) AS store_location,
    i.i_brand,
    regexp_extract(i.i_item_desc, '(\\d{3})') AS three_digit_code,
    ss.ss_net_profit,
    ss.ss_quantity
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE regexp_like(i.i_item_desc, '\\d{3}')
    AND s.s_store_name LIKE 'A%'
)
SELECT
  s_store_name,
  store_location,
  i_brand,
  three_digit_code,
  sum(ss_net_profit) AS total_profit,
  sum(ss_quantity) AS total_quantity,
  count(*) AS transaction_count
FROM filtered_sales
GROUP BY s_store_name, store_location, i_brand, three_digit_code
ORDER BY total_profit DESC
LIMIT 100
