WITH inv_daily AS (
    SELECT inv_date_sk,
           AVG(inv_quantity_on_hand) AS avg_qty
    FROM inventory
    GROUP BY inv_date_sk
)
SELECT
    s.s_store_name,
    we.web_name,
    d_sales.d_year,
    SUM(ss.ss_ext_sales_price)                         AS total_store_sales,
    SUM(ws.ws_ext_sales_price)                         AS total_web_sales,
    SUM(COALESCE(sr.sr_net_loss, 0))                   AS total_store_returns_loss,
    COUNT(DISTINCT ss.ss_item_sk)                      AS distinct_items_sold,
    inv_daily.avg_qty                                   AS avg_inventory_qty_on_sale_date,
    (SELECT AVG(inv_quantity_on_hand) FROM inventory) AS overall_avg_inventory_qty
FROM store_sales ss
JOIN date_dim d_sales        ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales        ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr   ON sr.sr_ticket_number = ss.ss_ticket_number
                              AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim d_return        ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return        ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN reason r                 ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws            ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_ws_sold       ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_sold       ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN ship_mode sm             ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we              ON ws.ws_web_site_sk = we.web_site_sk
JOIN date_dim d_ws_ship       ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN date_dim d_wp_creation   ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access     ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN customer c_wp            ON wp.wp_customer_sk = c_wp.c_customer_sk
JOIN call_center cc          ON cc.cc_open_date_sk = d_sales.d_date_sk
JOIN catalog_page cp          ON cp.cp_start_date_sk = d_sales.d_date_sk
JOIN inv_daily                ON inv_daily.inv_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 2001
  AND we.web_company_id = 2
  AND s.s_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND r2.r_reason_desc = 'Damaged'
    )
GROUP BY ROLLUP (s.s_store_name, we.web_name, d_sales.d_year, inv_daily.avg_qty)
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_store_sales DESC
LIMIT 100
