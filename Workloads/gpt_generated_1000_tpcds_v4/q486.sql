WITH cs_item AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
)
SELECT
    cs.i_category,
    cs.i_brand,
    w.w_warehouse_name,
    sm.sm_type AS ship_type,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss
FROM cs_item cs
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
   AND inv.inv_item_sk = cs.i_item_sk
JOIN store_sales ss
    ON ss.ss_item_sk = cs.i_item_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_sales ws
    ON ws.ws_item_sk = cs.i_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory inv2
    WHERE inv2.inv_item_sk = cs.i_item_sk
      AND inv2.inv_quantity_on_hand > 600
)
GROUP BY
    cs.i_category,
    cs.i_brand,
    w.w_warehouse_name,
    sm.sm_type
ORDER BY total_net_paid DESC
LIMIT 100
