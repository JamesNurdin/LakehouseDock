SELECT
  i.i_category,
  i.i_brand,
  p.p_promo_name,
  cc.cc_name,
  r_cr.r_reason_desc AS catalog_return_reason,
  r_wr.r_reason_desc AS web_return_reason,
  cd.cd_gender,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_transactions,
  SUM(ss.ss_ext_sales_price) AS total_sales_amount,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(wr.wr_return_amt) AS total_web_return_amount,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
  AVG(i.i_current_price) AS avg_item_price,
  MIN(ss.ss_sales_price) AS min_sales_price,
  MAX(ss.ss_sales_price) AS max_sales_price
FROM item i
INNER JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
INNER JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
INNER JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
INNER JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
INNER JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE
  i.i_units = 'Each'
  AND cc.cc_tax_percentage = 0.08
  AND inv.inv_quantity_on_hand > 500
GROUP BY
  i.i_category,
  i.i_brand,
  p.p_promo_name,
  cc.cc_name,
  r_cr.r_reason_desc,
  r_wr.r_reason_desc,
  cd.cd_gender
HAVING
  SUM(ss.ss_ext_sales_price) > 100000
  AND SUM(inv.inv_quantity_on_hand) > 1000
ORDER BY
  total_sales_amount DESC
LIMIT 100
