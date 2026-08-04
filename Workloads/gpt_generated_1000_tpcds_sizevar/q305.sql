WITH joined_data AS (
    SELECT
        d.d_date,
        d.d_year,
        c.c_customer_id,
        hd.hd_income_band_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ws.ws_order_number,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_return_quantity,
        cc.cc_name,
        cp.cp_catalog_page_number,
        cp.cp_department,
        wp.wp_url,
        sm.sm_type,
        r.r_reason_desc,
        wsite.web_market_manager,
        ROW_NUMBER() OVER (PARTITION BY wsite.web_market_manager ORDER BY ss.ss_net_profit DESC) AS rank_val
    FROM store_sales ss
    JOIN date_dim d                ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t_ss            ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr         ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r                 ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws            ON ws.ws_order_number = ss.ss_ticket_number
    JOIN ship_mode sm             ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite           ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr           ON wr.wr_order_number = ws.ws_order_number
    JOIN call_center cc           ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp          ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%size%'
      AND wsite.web_market_manager = 'James Harris'
      AND cp.cp_department = 'Electronics'
),
second_set AS (
    SELECT
        d_date,
        c_customer_id,
        ss_ticket_number,
        ws_order_number,
        ss_net_profit,
        ws_net_profit,
        wr_return_quantity,
        cc_name,
        cp_catalog_page_number,
        wp_url,
        sm_type,
        r_reason_desc,
        web_market_manager,
        DENSE_RANK() OVER (PARTITION BY sm_type ORDER BY ss_net_profit DESC) AS rank_val
    FROM joined_data
    WHERE cp_department = 'Clothing'
)
SELECT
    d_date,
    c_customer_id,
    ss_ticket_number,
    ws_order_number,
    ss_net_profit,
    ws_net_profit,
    wr_return_quantity,
    cc_name,
    cp_catalog_page_number,
    wp_url,
    sm_type,
    r_reason_desc,
    web_market_manager,
    rank_val
FROM joined_data
WHERE cp_department = 'Electronics'
UNION DISTINCT
SELECT
    d_date,
    c_customer_id,
    ss_ticket_number,
    ws_order_number,
    ss_net_profit,
    ws_net_profit,
    wr_return_quantity,
    cc_name,
    cp_catalog_page_number,
    wp_url,
    sm_type,
    r_reason_desc,
    web_market_manager,
    rank_val
FROM second_set
ORDER BY rank_val
LIMIT 100
