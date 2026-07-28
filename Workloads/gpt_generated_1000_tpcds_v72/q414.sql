WITH returned_sales AS (
  SELECT
    s.s_store_name,
    i.i_brand,
    i.i_product_name,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    r.r_reason_desc,
    cd.cd_gender,
    cd.cd_purchase_estimate,
    ss.ss_net_paid
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE regexp_like(r.r_reason_desc, '(?i)defect')
    AND i.i_item_desc LIKE '%gift%'
    AND cd.cd_gender = 'F'
    AND cd.cd_purchase_estimate > 5000
)
SELECT
  s_store_name,
  i_brand,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(cr_return_quantity) AS total_return_qty,
  COUNT(DISTINCT i_product_name) AS distinct_product_cnt,
  AVG(ss_net_paid) AS avg_net_paid
FROM returned_sales
GROUP BY s_store_name, i_brand
HAVING SUM(cr_return_amount) > (SELECT AVG(cr_return_amount) FROM catalog_returns)
ORDER BY total_return_amount DESC
LIMIT 100
