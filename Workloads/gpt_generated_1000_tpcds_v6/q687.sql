WITH joined_data AS (
    SELECT
        s.s_state AS store_state,
        wh_cat.w_state AS warehouse_state,
        sm_cat.sm_carrier AS ship_carrier,
        d_date.d_quarter_seq,
        cp.cp_department,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM date_dim d_date
    -- Catalog channel
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_date.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cat
        ON cs.cs_ship_mode_sk = sm_cat.sm_ship_mode_sk
    JOIN warehouse wh_cat
        ON cs.cs_warehouse_sk = wh_cat.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_date_sk = d_date.d_date_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN warehouse wh_cr
        ON cr.cr_warehouse_sk = wh_cr.w_warehouse_sk
    -- Store channel
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_date.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
        AND s.s_closed_date_sk = d_date.d_date_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d_date.d_date_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    -- Web channel
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_date.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse wh_ws
        ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d_date.d_date_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE
        d_date.d_year = 2002
        AND sm_cat.sm_carrier = 'DIAMOND'
        AND s.s_state = 'CA'
        AND wh_cat.w_state = 'TX'
        AND wp.wp_type = 'home'
        AND r_cr.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY
        s.s_state,
        wh_cat.w_state,
        sm_cat.sm_carrier,
        d_date.d_quarter_seq,
        cp.cp_department
),
final_agg AS (
    SELECT
        store_state,
        warehouse_state,
        ship_carrier,
        d_quarter_seq,
        cp_department,
        catalog_profit,
        store_profit,
        web_profit,
        (catalog_profit + store_profit + web_profit) AS total_profit
    FROM joined_data
    WHERE (catalog_profit + store_profit + web_profit) > 1000
)
SELECT
    store_state,
    warehouse_state,
    ship_carrier,
    d_quarter_seq,
    cp_department,
    catalog_profit,
    store_profit,
    web_profit,
    total_profit,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER () AS grand_total_profit
FROM final_agg
ORDER BY total_profit DESC
LIMIT 100
