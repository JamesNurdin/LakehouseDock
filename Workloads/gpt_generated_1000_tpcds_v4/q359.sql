WITH agg AS (
    SELECT
        d.d_year,
        cc.cc_state,
        i.i_brand,
        SUM(cr.cr_return_amount) AS total_cat_return_amt,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT cr.cr_order_number) AS cat_return_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
    FROM
        catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                           AND inv.inv_item_sk = i.i_item_sk
                           AND inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                           AND wr.wr_item_sk = i.i_item_sk
    WHERE
        d.d_year = 2000
        AND cc.cc_state = 'CA'
        AND cp.cp_department = 'Electronics'
        AND sm.sm_type = 'AIR'
        AND w.w_state = 'CA'
        AND i.i_brand = 'Brand#12'
        AND cr.cr_return_amount > 1000
        AND inv.inv_quantity_on_hand < 50
        AND wr.wr_return_amt > 200
    GROUP BY
        d.d_year,
        cc.cc_state,
        i.i_brand
)
SELECT
    d_year,
    cc_state,
    i_brand,
    (total_cat_return_amt + total_web_return_amt) AS net_return_amount,
    total_inventory_qty / NULLIF((cat_return_orders + web_return_orders), 0) AS avg_inventory_per_return_order
FROM agg
WHERE (total_cat_return_amt + total_web_return_amt) > 5000
ORDER BY net_return_amount DESC
LIMIT 100
