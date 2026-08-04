WITH sales_return_agg AS (
    SELECT
        w.w_state,
        ib.ib_income_band_sk,
        SUM(cs.cs_net_profit)                         AS total_net_profit,
        SUM(cr.cr_net_loss)                           AS total_net_loss,
        COUNT(DISTINCT cs.cs_order_number)            AS distinct_orders,
        COUNT(DISTINCT cs.cs_item_sk)                 AS distinct_items,
        AVG(cs.cs_ext_discount_amt)                  AS avg_discount_amt,
        SUM(i.inv_quantity_on_hand)                  AS total_inventory_qty
    FROM
        catalog_sales cs
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        JOIN web_sales ws
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
        JOIN inventory i
            ON i.inv_warehouse_sk = w.w_warehouse_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        w.w_state IN ('SC', 'GA')
        AND w.w_city = 'Shiloh'
        AND cs.cs_item_sk IN (132055, 198715)
        AND cs.cs_coupon_amt > 500
        AND cr.cr_return_quantity > 0
        AND wr.wr_reason_sk NOT IN (20, 58)
        AND ib.ib_lower_bound >= 120000
    GROUP BY
        w.w_state,
        ib.ib_income_band_sk
)
SELECT
    w_state,
    ib_income_band_sk,
    total_net_profit,
    total_net_loss,
    distinct_orders,
    distinct_items,
    avg_discount_amt,
    total_inventory_qty,
    (total_net_profit / NULLIF(total_net_loss, 0)) AS profit_to_loss_ratio
FROM
    sales_return_agg
WHERE
    total_net_profit > 0
ORDER BY
    total_net_profit DESC
