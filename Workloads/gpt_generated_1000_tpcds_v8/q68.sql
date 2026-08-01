SELECT
  cr.cr_order_number,
  p.p_promo_name,
  re.r_reason_desc,
  CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_type,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(s.cs_sales_price) AS avg_sales_price,
  COUNT(*) AS return_cnt,
  MAX(cr.cr_return_tax) AS max_return_tax
FROM tpcds.catalog_returns cr
JOIN tpcds.catalog_sales s
  ON cr.cr_item_sk = s.cs_item_sk
 AND cr.cr_order_number = s.cs_order_number
JOIN tpcds.promotion p
  ON s.cs_promo_sk = p.p_promo_sk
CROSS JOIN LATERAL (
  SELECT r.r_reason_desc
  FROM tpcds.reason r
  WHERE r.r_reason_sk = cr.cr_reason_sk
) AS re
WHERE cr.cr_return_tax > 5
  AND cr.cr_return_quantity = 1
  AND p.p_channel_catalog = 'N'
  AND p.p_response_target = 1
  AND s.cs_sales_price > 30
GROUP BY
  cr.cr_order_number,
  p.p_promo_name,
  re.r_reason_desc,
  p.p_discount_active
ORDER BY total_return_amount DESC
LIMIT 10
