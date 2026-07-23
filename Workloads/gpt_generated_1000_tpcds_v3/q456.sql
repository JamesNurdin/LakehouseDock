WITH distinct_customers AS (
    SELECT DISTINCT c.c_customer_sk,
           c.c_customer_id,
           c.c_birth_year,
           ca.ca_state
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1960
      AND ca.ca_state = 'CA'
),
base AS (
    SELECT
        dc.c_customer_id,
        i.i_category,
        r_sr.r_reason_desc AS r_reason_desc,
        SUM(COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_store_return,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_net_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM distinct_customers dc
    JOIN store_sales ss ON ss.ss_customer_sk = dc.c_customer_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_refunded_customer_sk = dc.c_customer_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                              AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                              AND wr.wr_refunded_customer_sk = dc.c_customer_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_current_price > 100
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND td.t_hour BETWEEN 9 AND 17
      AND wp.wp_image_count >= 5
      AND inv.inv_quantity_on_hand > 0
    GROUP BY dc.c_customer_id, i.i_category, r_sr.r_reason_desc
)
SELECT
    c_customer_id,
    i_category,
    r_reason_desc,
    total_sales,
    total_store_return,
    total_catalog_net_loss,
    total_web_net_loss,
    distinct_sales_tickets,
    avg_inventory_qty,
    (total_sales - total_store_return - total_catalog_net_loss - total_web_net_loss) AS net_revenue,
    CASE WHEN total_catalog_net_loss + total_web_net_loss > 0 THEN 'Returned' ELSE 'No Return' END AS return_flag
FROM base
WHERE total_sales > 1000
ORDER BY net_revenue DESC
LIMIT 100
