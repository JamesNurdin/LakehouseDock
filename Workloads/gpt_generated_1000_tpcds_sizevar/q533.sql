WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
)
SELECT
    p.p_promo_id,
    w_cs.w_state,
    cp.cp_catalog_number,
    CASE
        WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
        WHEN cs.cs_net_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    SUM(cs.cs_net_paid) AS total_sales,
    AVG(cs.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    inv_qty.total_inventory_qty
FROM
    store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN household_demographics hd_cs
        ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    LEFT JOIN customer_address ca_cs
        ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
    LEFT JOIN warehouse w_cs
        ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN income_band ib
        ON hd_cs.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN LATERAL (
        SELECT SUM(si.inv_quantity_on_hand) AS total_inventory_qty
        FROM sampled_inventory si
        WHERE si.inv_warehouse_sk = w_cs.w_warehouse_sk
    ) inv_qty ON TRUE
WHERE
    p.p_channel_radio = 'N'
    AND p.p_channel_event = 'N'
    AND cp.cp_catalog_page_number IN (1, 12)
    AND w_cs.w_state = 'CA'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
    )
GROUP BY
    p.p_promo_id,
    w_cs.w_state,
    cp.cp_catalog_number,
    CASE
        WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
        WHEN cs.cs_net_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END,
    inv_qty.total_inventory_qty
ORDER BY
    total_sales DESC
LIMIT 100
