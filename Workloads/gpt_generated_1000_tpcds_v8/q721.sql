WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_sold_time_sk,
        cp.cp_department,
        cc.cc_name,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        td.t_hour,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        ca.ca_state,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        sr.sr_return_quantity,
        wr.wr_return_quantity,
        wp.wp_url,
        -- LATERAL aggregate: total quantity on hand for the warehouse
        inv_lat.total_qty_warehouse
    FROM
        catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_returned_time_sk = td.t_time_sk
        JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
                               AND sr.sr_cdemo_sk = cd.cd_demo_sk
                               AND sr.sr_hdemo_sk = hd.hd_demo_sk
                               AND sr.sr_addr_sk = ca.ca_address_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
                               AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
                               AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
                               AND wr.wr_refunded_addr_sk = ca.ca_address_sk
                               AND wr.wr_reason_sk = r.r_reason_sk
        JOIN (SELECT * FROM web_page TABLESAMPLE BERNOULLI (10)) wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        -- LATERAL join to compute the total quantity on‑hand for the current warehouse
        CROSS JOIN LATERAL (
            SELECT sum(inv2.inv_quantity_on_hand) AS total_qty_warehouse
            FROM inventory inv2
            WHERE inv2.inv_warehouse_sk = w.w_warehouse_sk
        ) inv_lat
    WHERE
        w.w_warehouse_name = 'New'
        AND ib.ib_upper_bound > 90000
        AND td.t_hour IN (9, 18)
        AND cd.cd_gender = 'M'
        AND cs.cs_order_number IN (
            SELECT cr_returned_time_sk FROM catalog_returns
            INTERSECT
            SELECT sr_return_time_sk FROM store_returns
        )
        AND w.w_warehouse_sk IN (
            SELECT inv_warehouse_sk FROM inventory WHERE inv_quantity_on_hand > 1000
        )
),
union_data AS (
    SELECT
        b.cs_order_number AS order_no,
        b.cs_net_profit AS profit,
        b.w_warehouse_name
    FROM base b
    WHERE b.cs_quantity > 5
    UNION DISTINCT
    SELECT
        b.cs_order_number AS order_no,
        b.cs_net_profit AS profit,
        b.w_warehouse_name
    FROM base b
    WHERE b.cs_quantity <= 5
)
SELECT
    ud.order_no,
    ud.profit,
    ud.w_warehouse_name,
    RANK() OVER (PARTITION BY ud.w_warehouse_name ORDER BY ud.profit DESC) AS profit_rank,
    LAG(ud.profit) OVER (PARTITION BY ud.w_warehouse_name ORDER BY ud.profit) AS lag_profit,
    SUM(ud.profit) OVER (PARTITION BY ud.w_warehouse_name ORDER BY ud.profit ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit,
    b.total_qty_warehouse
FROM union_data ud
JOIN base b ON ud.order_no = b.cs_order_number
ORDER BY ud.profit DESC, ud.w_warehouse_name
LIMIT 100
