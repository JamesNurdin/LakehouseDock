WITH catalog_data AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        cp.cp_department,
        p.p_promo_id,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    INNER JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    INNER JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
),

web_data AS (
    SELECT
        w.w_warehouse_sk,
        wp.wp_type,
        p2.p_promo_id,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    INNER JOIN customer_demographics cd_bill_ws
        ON ws.ws_bill_cdemo_sk = cd_bill_ws.cd_demo_sk
    INNER JOIN customer_demographics cd_ship_ws
        ON ws.ws_ship_cdemo_sk = cd_ship_ws.cd_demo_sk
    INNER JOIN household_demographics hd_bill_ws
        ON ws.ws_bill_hdemo_sk = hd_bill_ws.hd_demo_sk
    INNER JOIN household_demographics hd_ship_ws
        ON ws.ws_ship_hdemo_sk = hd_ship_ws.hd_demo_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN promotion p2
        ON ws.ws_promo_sk = p2.p_promo_sk
),

inventory_data AS (
    SELECT
        w.w_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory inv
    INNER JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
)

SELECT
    cd.w_warehouse_id,
    cd.w_warehouse_name,
    cd.cp_department,
    wd.wp_type,
    SUM(cd.cs_net_profit) AS catalog_net_profit,
    SUM(wd.ws_net_profit) AS web_net_profit,
    SUM(cd.cs_quantity) + SUM(wd.ws_quantity) AS total_quantity,
    COUNT(DISTINCT cd.cs_bill_customer_sk) AS distinct_catalog_customers,
    COUNT(DISTINCT wd.ws_bill_customer_sk) AS distinct_web_customers,
    id.total_inventory_on_hand,
    (SELECT COUNT(DISTINCT p_inner.p_promo_id)
     FROM promotion p_inner
     JOIN catalog_sales cs_inner
       ON cs_inner.cs_promo_sk = p_inner.p_promo_sk
     WHERE cs_inner.cs_warehouse_sk = cd.w_warehouse_sk) AS distinct_catalog_promos,
    (SELECT COUNT(DISTINCT p_ws.p_promo_id)
     FROM promotion p_ws
     JOIN web_sales ws_inner
       ON ws_inner.ws_promo_sk = p_ws.p_promo_sk
     WHERE ws_inner.ws_warehouse_sk = cd.w_warehouse_sk) AS distinct_web_promos
FROM catalog_data cd
INNER JOIN web_data wd
    ON cd.w_warehouse_sk = wd.w_warehouse_sk
INNER JOIN inventory_data id
    ON cd.w_warehouse_sk = id.w_warehouse_sk
GROUP BY
    cd.w_warehouse_id,
    cd.w_warehouse_name,
    cd.cp_department,
    wd.wp_type,
    id.total_inventory_on_hand,
    cd.w_warehouse_sk
ORDER BY (SUM(cd.cs_net_profit) + SUM(wd.ws_net_profit)) DESC
LIMIT 100
