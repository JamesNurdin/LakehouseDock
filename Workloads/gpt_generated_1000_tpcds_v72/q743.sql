WITH sales AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_item_sk,
    ss.ss_store_sk,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit
  FROM store_sales ss
  WHERE ss.ss_quantity > 0
)
SELECT
  s.s_state,
  i.i_brand,
  i.i_item_desc,
  concat(i.i_brand, ' - ', i.i_item_desc) AS brand_item,
  regexp_extract(i.i_item_desc, '(\\d+)', 1) AS first_number,
  SUM(sales.ss_quantity) AS total_quantity,
  SUM(sales.ss_net_paid) AS total_net_paid,
  SUM(sales.ss_net_profit) AS total_profit
FROM sales
JOIN item i ON sales.ss_item_sk = i.i_item_sk
JOIN store s ON sales.ss_store_sk = s.s_store_sk
JOIN time_dim t ON sales.ss_sold_time_sk = t.t_time_sk
WHERE
  i.i_item_desc LIKE '%a%'
  AND regexp_like(i.i_item_desc, '[0-9]')
  AND NOT EXISTS (
    SELECT 1 FROM inventory inv WHERE inv.inv_item_sk = i.i_item_sk
  )
GROUP BY ROLLUP (s.s_state, i.i_brand, i.i_item_desc)
ORDER BY s.s_state NULLS FIRST, i.i_brand NULLS LAST, total_net_paid DESC
LIMIT 100
