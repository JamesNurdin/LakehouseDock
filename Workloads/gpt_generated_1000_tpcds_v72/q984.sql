WITH raw_join AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_state,
        cc.cc_name,
        cp.cp_type,
        sm.sm_type,
        cs.cs_order_number,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid,
        cr.cr_fee,
        cr.cr_return_quantity
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
     AND cr.cr_call_center_sk = cc.cc_call_center_sk
     AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
     AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_rec_end_date = DATE '2000-12-31'
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'Electronics'
      AND sm.sm_carrier = 'UPS'
      AND cs.cs_ext_discount_amt > 500
      AND cr.cr_fee < 20
),
distinct_orders AS (
    SELECT DISTINCT
        cs_order_number,
        cc_state,
        sm_type,
        cs_net_paid,
        cs_ext_discount_amt,
        cr_fee,
        cr_return_quantity
    FROM raw_join
)
SELECT
    COALESCE(state, 'All States')        AS state,
    COALESCE(ship_type, 'All Ship Types') AS ship_type,
    SUM(net_paid)           AS total_net_paid,
    SUM(ext_discount_amt)   AS total_discount,
    SUM(fee)                AS total_fee,
    SUM(return_qty)         AS total_return_qty,
    COUNT(DISTINCT order_number) AS distinct_orders,
    RANK() OVER (ORDER BY SUM(net_paid) DESC) AS sales_rank
FROM (
    SELECT
        cc_state AS state,
        sm_type AS ship_type,
        cs_order_number AS order_number,
        cs_net_paid AS net_paid,
        cs_ext_discount_amt AS ext_discount_amt,
        cr_fee AS fee,
        cr_return_quantity AS return_qty
    FROM distinct_orders
) agg
GROUP BY ROLLUP (state, ship_type)
HAVING SUM(net_paid) > 0
ORDER BY sales_rank
LIMIT 100
