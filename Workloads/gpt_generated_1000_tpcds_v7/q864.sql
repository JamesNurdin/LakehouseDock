SELECT
  d.d_year,
  p.p_promo_name,
  COUNT(DISTINCT i.i_item_id) AS distinct_items,
  SUM(ss.ss_quantity) AS total_quantity,
  SUM(ss.ss_net_paid) AS total_net_paid,
  CONCAT('PROMO_', CAST(p.p_promo_sk AS VARCHAR)) AS promo_key,
  SUBSTRING(i.i_item_desc FROM 1 FOR 10) AS desc_prefix,
  REGEXP_EXTRACT(i.i_item_desc, '(?i)(blue|red|green)', 1) AS matched_color
FROM tpcds.store_sales ss
JOIN tpcds.date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND REGEXP_LIKE(i.i_item_desc, '(?i)blue')
  AND p.p_promo_name LIKE '%Discount%'
GROUP BY
  d.d_year,
  p.p_promo_name,
  p.p_promo_sk,
  i.i_item_desc,
  REGEXP_EXTRACT(i.i_item_desc, '(?i)(blue|red|green)', 1)
ORDER BY total_net_paid DESC
LIMIT 50
