WITH filtered_sales AS (
  SELECT ss.*, d.d_year
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 1999
)
SELECT
  fs.d_year,
  s.s_state,
  cd.cd_gender,
  i.i_category,
  SUM(fs.ss_net_paid) AS total_net_paid,
  SUM(fs.ss_net_profit) AS total_net_profit,
  SUM(fs.ss_ext_discount_amt) AS total_discount_amount,
  COUNT(*) AS transactions,
  SUM(fs.ss_net_profit) / NULLIF(SUM(fs.ss_net_paid), 0) AS profit_margin
FROM filtered_sales fs
JOIN store s ON fs.ss_store_sk = s.s_store_sk
JOIN item i ON fs.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON fs.ss_cdemo_sk = cd.cd_demo_sk
WHERE s.s_state IN ('CA', 'TX', 'NY')
  AND i.i_category = 'Electronics'
GROUP BY fs.d_year, s.s_state, cd.cd_gender, i.i_category
ORDER BY fs.d_year, s.s_state, cd.cd_gender, i.i_category
LIMIT 200
