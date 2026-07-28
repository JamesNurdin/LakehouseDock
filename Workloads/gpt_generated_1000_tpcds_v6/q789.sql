WITH joined_data AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        sm.sm_type,
        w.w_state,
        SUM(cs.cs_net_paid) AS cs_net_paid,
        SUM(ws.ws_net_paid) AS ws_net_paid,
        SUM(ss.ss_net_paid) AS ss_net_paid,
        SUM(cs.cs_net_profit) AS cs_net_profit,
        SUM(ws.ws_net_profit) AS ws_net_profit,
        SUM(ss.ss_net_profit) AS ss_net_profit,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
    WHERE i.i_brand = 'BrandX'
      AND sm.sm_carrier = 'AIRBORNE'
      AND w.w_state = 'CA'
    GROUP BY i.i_item_sk, i.i_category, i.i_brand, sm.sm_type, w.w_state
),
aggregated AS (
    SELECT
        i_category,
        sm_type,
        cs_net_paid,
        ws_net_paid,
        ss_net_paid,
        cs_net_profit,
        ws_net_profit,
        ss_net_profit,
        total_inventory,
        i_brand
    FROM joined_data
)
SELECT
    i_category,
    sm_type,
    SUM(cs_net_paid + ws_net_paid + ss_net_paid) AS total_net_paid,
    SUM(cs_net_profit + ws_net_profit + ss_net_profit) AS total_net_profit,
    AVG(total_inventory) AS avg_inventory_on_hand,
    SUM(CASE WHEN (cs_net_profit + ws_net_profit + ss_net_profit) > 10000 THEN 1 ELSE 0 END) AS high_profit_items
FROM aggregated
WHERE i_brand = 'BrandX'
GROUP BY GROUPING SETS (
    (i_category, sm_type),
    (i_category),
    ()
)
HAVING SUM(cs_net_paid + ws_net_paid + ss_net_paid) > 50000
ORDER BY total_net_paid DESC
LIMIT 100
