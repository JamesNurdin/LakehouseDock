WITH intersect_items AS (
    SELECT inv_item_sk AS item_sk
    FROM inventory
    INTERSECT
    SELECT cs_item_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
    )
)
SELECT
    s.s_store_name,
    cc.cc_name AS call_center_name,
    we.web_city,
    d_sold.d_year,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    (SUM(cs.cs_quantity) + SUM(ss.ss_quantity) + SUM(ws.ws_quantity)) AS total_quantity,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_band_upper_bound
FROM catalog_sales cs
JOIN intersect_items ii
    ON cs.cs_item_sk = ii.item_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cs
    ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN warehouse w_cs
    ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
-- Store sales side
JOIN store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_ss_sold
    ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
-- Web sales side
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
-- Inventory side
JOIN inventory inv
    ON inv.inv_item_sk = cs.cs_item_sk
JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
JOIN warehouse w_inv
    ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
WHERE cs.cs_bill_customer_sk IN (
    SELECT c2.c_customer_sk
    FROM customer c2
    WHERE c2.c_birth_year = 1955
)
GROUP BY
    s.s_store_name,
    cc.cc_name,
    we.web_city,
    d_sold.d_year
ORDER BY total_quantity DESC
LIMIT 100
