WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_category,
    w.w_warehouse_name,
    cp.cp_department,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(wr.wr_net_loss) AS total_web_returns_loss,
    inv_agg.total_quantity_on_hand,
    (
        SELECT AVG(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
    ) AS avg_web_sales_per_item
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
    AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
WHERE ib.ib_upper_bound > 150000
  AND p.p_discount_active = 'Y'
GROUP BY
    i.i_category,
    w.w_warehouse_name,
    cp.cp_department,
    inv_agg.total_quantity_on_hand,
    i.i_item_sk
ORDER BY total_catalog_profit DESC
LIMIT 100
