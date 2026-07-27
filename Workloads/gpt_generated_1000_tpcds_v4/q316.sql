WITH base AS (
    SELECT
        cc.cc_call_center_id AS cc_call_center_id,
        sm.sm_carrier AS sm_carrier,
        r.r_reason_desc AS r_reason_desc,
        cs.cs_net_profit AS cs_net_profit,
        cr.cr_net_loss AS cr_net_loss,
        ss.ss_net_paid AS ss_net_paid,
        wr.wr_net_loss AS wr_net_loss,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        c.c_customer_id AS c_customer_id
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_manager = 'Gregory Altman'
      AND sm.sm_carrier = 'UPS'
      AND w.w_state = 'CA'
),
agg AS (
    SELECT
        cc_call_center_id,
        sm_carrier,
        r_reason_desc,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cr_net_loss) AS total_return_loss,
        SUM(ss_net_paid) AS total_store_sales,
        SUM(wr_net_loss) AS total_web_return_loss,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(DISTINCT c_customer_id) AS distinct_customers
    FROM base
    GROUP BY cc_call_center_id, sm_carrier, r_reason_desc
)
SELECT
    a.cc_call_center_id,
    a.sm_carrier,
    a.r_reason_desc,
    a.total_net_profit,
    a.total_return_loss,
    a.total_store_sales,
    a.total_web_return_loss,
    a.avg_inventory_on_hand,
    a.distinct_customers
FROM agg a
WHERE a.total_net_profit > (
        SELECT AVG(total_net_profit) FROM agg
    )
  AND a.avg_inventory_on_hand > 1000
  AND a.r_reason_desc IN (
        SELECT r_reason_desc FROM reason WHERE r_reason_desc LIKE '%damage%'
    )
ORDER BY a.total_net_profit DESC
LIMIT 100
