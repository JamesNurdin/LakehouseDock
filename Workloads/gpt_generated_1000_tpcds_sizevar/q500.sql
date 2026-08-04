WITH filtered_returns AS (
  SELECT
    cr.cr_returned_date_sk,
    d.d_date,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    i.i_item_id,
    i.i_product_name,
    cp.cp_department,
    cp.cp_description,
    cust.c_customer_id
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
  WHERE regexp_like(cp.cp_description, '(?i)electronics')
    AND cp.cp_type LIKE 'C_%'
)
SELECT customer_id
FROM (
  SELECT
    fr.c_customer_id AS customer_id,
    fr.cp_department,
    SUM(fr.cr_return_amount) AS total_ret,
    CASE WHEN SUM(fr.cr_return_amount) > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
  FROM filtered_returns fr
  WHERE fr.cp_description LIKE '%TV%'
    AND regexp_extract(fr.cp_description, '(TV|Radio)', 1) IS NOT NULL
  GROUP BY GROUPING SETS ((fr.c_customer_id, fr.cp_department), (fr.c_customer_id))
  HAVING SUM(fr.cr_return_amount) > 500
) a
INTERSECT
SELECT customer_id
FROM (
  SELECT
    fr.c_customer_id AS customer_id,
    fr.cp_department,
    SUM(fr.cr_return_quantity) AS total_qty,
    CASE WHEN SUM(fr.cr_return_quantity) > 20 THEN 'BUSY' ELSE 'CALM' END AS qty_category
  FROM filtered_returns fr
  WHERE fr.cp_description LIKE '%Laptop%'
    AND regexp_like(fr.cp_description, '(?i)gaming')
    AND substr(fr.cp_description, 1, 3) = 'Lap'
  GROUP BY GROUPING SETS ((fr.c_customer_id, fr.cp_department), (fr.c_customer_id))
  HAVING SUM(fr.cr_return_quantity) >= 10
) b
ORDER BY customer_id
LIMIT 100
