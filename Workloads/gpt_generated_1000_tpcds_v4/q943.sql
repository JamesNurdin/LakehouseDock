WITH
    filtered_items AS (
        SELECT i_item_sk
        FROM item
        WHERE i_wholesale_cost < 5
    ),
    sport_avg AS (
        SELECT avg(i_current_price) AS avg_price
        FROM item
        WHERE i_category = 'Sports'
    )
SELECT
    cc.cc_city,
    d_ret.d_year,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    AVG(i.i_current_price) AS avg_item_price,
    (SELECT avg_price FROM sport_avg) AS sport_category_avg_price
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd_refund
    ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN customer_demographics cd_return
    ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
WHERE EXISTS (
        SELECT 1
        FROM filtered_items fi
        WHERE fi.i_item_sk = cr.cr_item_sk
      )
  AND i.i_current_price > (SELECT avg_price FROM sport_avg)
  AND cp.cp_type = 'PROMO'
  AND sm.sm_type = 'AIR'
  AND d_ret.d_year BETWEEN 2000 AND 2002
GROUP BY
    cc.cc_city,
    d_ret.d_year
ORDER BY
    total_net_loss DESC,
    cc.cc_city
LIMIT 100
