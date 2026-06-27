SELECT
  p.p_promo_id,
  p.p_promo_name,
  cp.cp_department,
  i.i_category,
  d.d_year,
  date_format(d.d_date, '%Y-%m') AS year_month,
  sum(cs.cs_net_profit) AS total_net_profit,
  sum(cs.cs_quantity) AS total_quantity,
  avg(cs.cs_ext_discount_amt) AS avg_discount_amount
FROM catalog_sales cs
JOIN date_dim d          ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i              ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p         ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w         ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
GROUP BY
  p.p_promo_id,
  p.p_promo_name,
  cp.cp_department,
  i.i_category,
  d.d_year,
  date_format(d.d_date, '%Y-%m')
HAVING sum(cs.cs_quantity) > 1000
ORDER BY total_net_profit DESC
LIMIT 20
