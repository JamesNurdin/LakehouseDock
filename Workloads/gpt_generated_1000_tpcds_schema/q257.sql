WITH brand_avg AS (
   SELECT i_brand, AVG(i_wholesale_cost) AS avg_wholesale_cost
   FROM item
   GROUP BY i_brand
)
SELECT
    cc.cc_division_name,
    cc.cc_city,
    sm.sm_carrier,
    i.i_product_name,
    cr.cr_return_amount,
    cr.cr_return_tax,
    CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_category,
    ba.avg_wholesale_cost,
    RANK() OVER (PARTITION BY cc.cc_division_name ORDER BY cr.cr_return_amount DESC) AS amount_rank
FROM catalog_returns cr
FULL OUTER JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
INNER JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN brand_avg ba
    ON i.i_brand = ba.i_brand
WHERE cp.cp_end_date_sk BETWEEN 2450800 AND 2451200
  AND i.i_wholesale_cost > 5
  AND sm.sm_carrier = 'AIRBORNE'
  AND cc.cc_state = 'CA'
  AND cr.cr_return_tax > 10
ORDER BY amount_rank ASC, cc.cc_division_name
