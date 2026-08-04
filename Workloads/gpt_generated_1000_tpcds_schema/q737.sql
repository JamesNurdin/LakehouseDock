WITH intersect_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    INTERSECT
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
),
base AS (
    SELECT
        cs.cs_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        s.s_store_name,
        sm.sm_carrier AS catalog_ship_carrier,
        sm_ws.sm_carrier AS web_ship_carrier,
        wp.wp_url,
        cs.cs_order_number,
        cs.cs_net_paid,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ws.ws_order_number,
        ws.ws_net_paid,
        i1.i_category,
        (
            SELECT SUM(inv2.inv_quantity_on_hand)
            FROM inventory inv2
            WHERE inv2.inv_item_sk = cs.cs_item_sk
        ) AS total_inventory_qty
    FROM catalog_sales cs
    JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i1 ON cs.cs_item_sk = i1.i_item_sk
    JOIN inventory inv ON i1.i_item_sk = inv.inv_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i1.i_item_sk
    JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
    JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i1.i_item_sk
    JOIN item i3 ON ws.ws_item_sk = i3.i_item_sk
    JOIN time_dim t3 ON ws.ws_sold_time_sk = t3.t_time_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE EXISTS (
        SELECT 1 FROM inventory inv_check
        WHERE inv_check.inv_item_sk = cs.cs_item_sk
          AND inv_check.inv_quantity_on_hand > 0
    )
      AND cs.cs_item_sk IN (SELECT item_sk FROM intersect_items)
      AND cs.cs_coupon_amt > 1000
),
agg AS (
    SELECT
        cs_bill_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        s_store_name,
        catalog_ship_carrier,
        web_ship_carrier,
        wp_url,
        i_category,
        COUNT(DISTINCT cs_order_number) AS distinct_catalog_orders,
        COUNT(DISTINCT ss_ticket_number) AS distinct_store_tickets,
        SUM(cs_net_paid) AS total_catalog_net_paid,
        SUM(ss_net_paid) AS total_store_net_paid,
        SUM(ws_net_paid) AS total_web_net_paid,
        SUM(total_inventory_qty) AS total_inventory_quantity
    FROM base
    GROUP BY
        cs_bill_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        s_store_name,
        catalog_ship_carrier,
        web_ship_carrier,
        wp_url,
        i_category
)
SELECT
    cs_bill_customer_sk,
    c_first_name,
    c_last_name,
    CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_category,
    s_store_name,
    catalog_ship_carrier,
    web_ship_carrier,
    wp_url,
    i_category,
    distinct_catalog_orders,
    distinct_store_tickets,
    total_catalog_net_paid,
    total_store_net_paid,
    total_web_net_paid,
    total_inventory_quantity,
    LAG(total_catalog_net_paid) OVER (PARTITION BY cs_bill_customer_sk ORDER BY total_catalog_net_paid) AS lag_total_catalog_net_paid
FROM agg
ORDER BY total_catalog_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
