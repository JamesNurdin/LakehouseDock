WITH base AS (
    SELECT
        d.d_year,
        d.d_date,
        cs.cs_order_number,
        cs.cs_net_profit AS catalog_net_profit,
        cr.cr_net_loss,
        ws.ws_net_profit AS web_net_profit,
        sr.sr_net_loss,
        cc.cc_name,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        inv.inv_quantity_on_hand,
        r.r_reason_desc,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        wp.wp_url,
        web.web_name
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    LEFT JOIN tpcds.warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.reason r ON r.r_reason_sk = cr.cr_reason_sk
    LEFT JOIN tpcds.customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN tpcds.customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
    LEFT JOIN tpcds.web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN tpcds.web_site web ON web.web_site_sk = ws.ws_web_site_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc IS NOT NULL
      AND c.c_first_name = 'John'
      AND ca.ca_state = 'CA'
      AND w.w_city = 'Los Angeles'
),
agg AS (
    SELECT
        d_year,
        ship_mode_type,
        cc_name,
        SUM(COALESCE(catalog_net_profit, 0) - COALESCE(cr_net_loss, 0) + COALESCE(web_net_profit, 0) - COALESCE(sr_net_loss, 0)) AS total_net_amount,
        COUNT(*) AS txn_count,
        SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory_qty,
        CASE WHEN SUM(COALESCE(inv_quantity_on_hand, 0)) = 0 THEN 'No Inventory' ELSE 'Has Inventory' END AS inventory_status
    FROM base
    GROUP BY d_year, ship_mode_type, cc_name
    HAVING SUM(COALESCE(catalog_net_profit, 0) - COALESCE(cr_net_loss, 0) + COALESCE(web_net_profit, 0) - COALESCE(sr_net_loss, 0)) > 10000
)
SELECT
    d_year,
    ship_mode_type,
    cc_name,
    total_net_amount,
    txn_count,
    inventory_status,
    AVG(total_net_amount) OVER (PARTITION BY ship_mode_type) AS avg_total_net_by_ship_mode
FROM agg
ORDER BY total_net_amount DESC
LIMIT 100
