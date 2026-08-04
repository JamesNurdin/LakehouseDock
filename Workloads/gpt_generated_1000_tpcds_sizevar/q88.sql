/* Goal: Analyze high‑value product returns by call center, catalog page and geographic address, focusing on a subset of brands, price ranges and business hours. */
WITH filtered_items AS (
    SELECT i_item_sk,
           i_brand,
           i_current_price,
           i_category
    FROM   item
    WHERE  i_brand IN ('BrandA', 'BrandB')
       AND i_current_price > 50
)
SELECT
    cc.cc_name                             AS call_center_name,
    cp.cp_catalog_number                   AS catalog_number,
    ca_refunded.ca_state                   AS refunded_state,
    ca_returning.ca_state                  AS returning_state,
    SUM(cr.cr_return_amount)               AS total_return_amount,
    AVG(cr.cr_return_tax)                  AS avg_return_tax,
    COUNT(DISTINCT cr.cr_order_number)    AS distinct_orders,
    MIN(cr.cr_return_ship_cost)            AS min_ship_cost,
    MAX(fi.i_current_price)                AS max_item_price
FROM   catalog_returns cr
JOIN   call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN   catalog_page cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN   filtered_items fi
       ON cr.cr_item_sk = fi.i_item_sk
JOIN   time_dim td
       ON cr.cr_returned_time_sk = td.t_time_sk
JOIN   customer_address ca_refunded
       ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN   customer_address ca_returning
       ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
WHERE  cr.cr_return_ship_cost > 100
  AND  cr.cr_return_amount BETWEEN 200 AND 5000
  AND  cc.cc_company = 4
  AND  cc.cc_sq_ft > 1000000
  AND  cp.cp_catalog_number IN (16, 19)
  AND  td.t_hour BETWEEN 9 AND 17
  AND  EXISTS (
        SELECT 1
        FROM   catalog_page cp2
        WHERE  cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
          AND  cp2.cp_type = 'Electronic'
       )
GROUP BY
    cc.cc_name,
    cp.cp_catalog_number,
    ca_refunded.ca_state,
    ca_returning.ca_state
ORDER BY total_return_amount DESC
LIMIT 100
