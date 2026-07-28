WITH agg AS (
    SELECT
        d.d_year,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        SUM(CASE WHEN cr.cr_net_loss IS NOT NULL THEN cr.cr_net_loss ELSE 0 END) AS total_return_loss,
        SUM(CASE WHEN sr.sr_net_loss IS NOT NULL THEN sr.sr_net_loss ELSE 0 END) AS total_store_return_loss
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_order_number = cs.cs_order_number
            AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
            AND cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
        JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
            AND wp.wp_customer_sk = c.c_customer_sk
    WHERE
        d.d_year BETWEEN 2001 AND 2002
        AND s.s_state = 'CA'
        AND ca.ca_country = 'United States'
        AND sm.sm_type = 'AIR'
        AND w.w_state = 'TX'
        AND r_sr.r_reason_desc LIKE '%damage%'
        AND wp.wp_type = 'Home'
    GROUP BY
        d.d_year,
        s.s_store_name,
        s.s_state
)
SELECT
    d_year,
    s_store_name,
    s_state,
    total_store_profit,
    total_transactions,
    total_return_loss,
    total_store_return_loss,
    CASE
        WHEN total_store_profit > 100000 THEN 'HIGH'
        WHEN total_store_profit > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_store_profit DESC) AS profit_rank_year,
    ROW_NUMBER() OVER (ORDER BY total_store_profit DESC) AS overall_rank
FROM agg
ORDER BY d_year, profit_rank_year
LIMIT 100
