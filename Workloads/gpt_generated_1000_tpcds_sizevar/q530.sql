WITH base AS (
    SELECT
        s.s_store_name,
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        d_ss.d_year,
        ss.ss_net_profit,
        CASE WHEN ss.ss_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        cs.cs_order_number,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_order_number,
        ws.ws_net_profit AS ws_net_profit,
        cr.cr_return_quantity,
        r_cr.r_reason_desc AS cr_reason,
        r_wr.r_reason_desc AS wr_reason,
        wp.wp_url,
        webs.web_name,
        sm_cs.sm_type AS cs_ship_mode,
        sm_ws.sm_type AS ws_ship_mode,
        w_cs.w_warehouse_name AS cs_warehouse,
        w_ws.w_warehouse_name AS ws_warehouse,
        cp.cp_department,
        cc.cc_name,
        -- scalar subquery: total distinct customers across store_sales and web_sales
        (SELECT COUNT(DISTINCT cust_id) FROM (
            SELECT ss_customer_sk AS cust_id FROM store_sales
            UNION ALL
            SELECT ws_bill_customer_sk FROM web_sales
        )) AS total_distinct_customers
    FROM store s
    FULL OUTER JOIN store_sales ss
        ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    LEFT JOIN warehouse w_cs
        ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_ss.d_date_sk
       AND ws.ws_sold_time_sk = t_ss.t_time_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site webs
        ON ws.ws_web_site_sk = webs.web_site_sk
    LEFT JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
),
union_part AS (
    SELECT
        s_store_name,
        profit_category,
        d_year,
        SUM(ss_net_profit) AS total_profit,
        total_distinct_customers,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM base
    WHERE d_year = 2000
    GROUP BY s_store_name, profit_category, d_year, total_distinct_customers
    UNION DISTINCT
    SELECT
        s_store_name,
        profit_category,
        d_year,
        SUM(ss_net_profit) AS total_profit,
        total_distinct_customers,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM base
    WHERE d_year = 2001
    GROUP BY s_store_name, profit_category, d_year, total_distinct_customers
),
intersect_part AS (
    SELECT cs_order_number AS order_id FROM catalog_sales
    INTERSECT
    SELECT ws_order_number FROM web_sales
)
SELECT
    up.s_store_name,
    up.profit_category,
    up.d_year,
    up.total_profit,
    up.total_distinct_customers,
    up.profit_rank,
    CASE WHEN ip.order_id IS NOT NULL THEN 'Common' ELSE 'Unique' END AS order_presence
FROM union_part up
LEFT JOIN intersect_part ip ON up.profit_rank = 1 AND ip.order_id = up.profit_rank
ORDER BY up.total_profit DESC
LIMIT 100
