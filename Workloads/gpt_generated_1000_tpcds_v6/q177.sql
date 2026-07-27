WITH base AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        sm.sm_carrier,
        w.w_warehouse_name,
        inv.inv_quantity_on_hand,
        cs.cs_net_profit,
        ss.ss_net_paid,
        wr.wr_return_amt,
        r.r_reason_desc
    FROM household_demographics hd
    JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state = 'PA'
      AND sm.sm_carrier = 'USPS'
      AND inv.inv_quantity_on_hand > 200
)
SELECT
    cc_name,
    cc_state,
    sm_carrier,
    w_warehouse_name,
    inv_quantity_on_hand,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(wr_return_amt) AS total_return_amount,
    CASE
        WHEN SUM(cs_net_profit) > (SELECT AVG(cs_net_profit) FROM catalog_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    RANK() OVER (PARTITION BY cc_state ORDER BY SUM(cs_net_profit) DESC) AS profit_rank_state
FROM base
GROUP BY
    cc_name,
    cc_state,
    sm_carrier,
    w_warehouse_name,
    inv_quantity_on_hand
ORDER BY profit_rank_state, total_net_profit DESC
LIMIT 100
