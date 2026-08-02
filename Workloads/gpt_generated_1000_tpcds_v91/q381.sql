SELECT
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    MIN(cr.cr_fee) AS min_fee,
    MAX(cr.cr_fee) AS max_fee,
    (SELECT SUM(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_warehouse_sk = cr.cr_warehouse_sk) AS warehouse_total_return_amount
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca
  ON cr.cr_returning_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2001
  AND w.w_suite_number = 'Suite 260'
  AND i.i_current_price BETWEEN 10 AND 100
  AND cr.cr_fee > 20
  AND EXISTS (
        SELECT 1
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
          AND cp.cp_catalog_page_number IN (1, 5)
      )
GROUP BY
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    cr.cr_warehouse_sk
ORDER BY total_return_amount DESC
LIMIT 100
