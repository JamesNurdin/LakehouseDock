WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS item_cnt
    FROM inventory
    WHERE inv_quantity_on_hand > 100
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    sm.sm_carrier,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    CASE WHEN SUM(cs.cs_net_paid) > 50000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category,
    inv_agg.total_qty,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
    ) AS avg_profit_per_warehouse
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN store_returns sr
    ON sr.sr_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN web_sales ws
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE sm.sm_carrier = 'FEDEX'
  AND sm.sm_type = 'AIR'
  AND i.inv_quantity_on_hand > 500
  AND w.w_state = 'CA'
  AND ib.ib_upper_bound <= 60000
  AND cs.cs_order_number IN (
        SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 5
        INTERSECT
        SELECT ws_order_number FROM web_sales WHERE ws_quantity > 5
    )
GROUP BY
    w.w_warehouse_id,
    w.w_city,
    sm.sm_carrier,
    inv_agg.total_qty,
    w.w_warehouse_sk
ORDER BY total_net_paid DESC
LIMIT 100
