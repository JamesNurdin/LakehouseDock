WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_qty
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ss_item_sk, ss_sold_date_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d_sold.d_date,
    ss_agg.total_qty,
    ss_agg.total_net_paid,
    CASE WHEN ss_agg.total_net_paid > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
    inv.inv_quantity_on_hand,
    cc.cc_name,
    cp.cp_department,
    ws.ws_net_paid,
    ws.ws_quantity,
    cr.sr_fee,
    CASE WHEN EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_returned_date_sk = d_sold.d_date_sk
        LIMIT 1
    ) THEN 1 ELSE 0 END AS has_return
FROM ss_agg
JOIN item i ON ss_agg.ss_item_sk = i.i_item_sk
JOIN date_dim d_sold ON ss_agg.ss_sold_date_sk = d_sold.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_sold.d_date_sk
LEFT JOIN call_center cc
    ON cc.cc_open_date_sk = d_sold.d_date_sk
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
-- Join a raw store_sales row to connect returns and customer info
JOIN store_sales ss_raw ON ss_raw.ss_ticket_number = (
        SELECT MIN(ss2.ss_ticket_number)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
          AND ss2.ss_sold_date_sk = d_sold.d_date_sk
    )
JOIN store_returns cr ON cr.sr_ticket_number = ss_raw.ss_ticket_number
JOIN customer c ON ss_raw.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
WHERE cd.cd_purchase_estimate >= 5000
GROUP BY
    i.i_item_id,
    i.i_product_name,
    d_sold.d_date,
    ss_agg.total_qty,
    ss_agg.total_net_paid,
    CASE WHEN ss_agg.total_net_paid > 100000 THEN 'HIGH' ELSE 'LOW' END,
    inv.inv_quantity_on_hand,
    cc.cc_name,
    cp.cp_department,
    ws.ws_net_paid,
    ws.ws_quantity,
    cr.sr_fee,
    CASE WHEN EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_returned_date_sk = d_sold.d_date_sk
        LIMIT 1
    ) THEN 1 ELSE 0 END
ORDER BY ss_agg.total_net_paid DESC
LIMIT 100
