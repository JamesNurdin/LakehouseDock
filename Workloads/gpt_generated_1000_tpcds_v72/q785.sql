WITH base AS (
    SELECT
        cp.cp_department AS department,
        cd.cd_gender AS gender,
        we.web_name AS website,
        w.w_state AS warehouse_state,
        r.r_reason_desc AS return_reason,
        CASE WHEN (COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        cs.cs_ext_list_price AS cs_ext_list_price,
        ss.ss_list_price AS ss_list_price,
        ws.ws_net_paid AS ws_net_paid,
        c.c_birth_year,
        sm.sm_type,
        (COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) AS combined_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE cs.cs_ext_list_price > 5000
      AND ss.ss_list_price > 20
      AND ws.ws_net_paid > 1000
      AND c.c_birth_year BETWEEN 1960 AND 1980
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
)
SELECT
    department,
    gender,
    website,
    warehouse_state,
    return_reason,
    profit_category,
    SUM(combined_profit) AS total_profit,
    COUNT(*) AS order_count,
    AVG(cs_ext_list_price) AS avg_catalog_price,
    AVG(ss_list_price) AS avg_store_price,
    AVG(ws_net_paid) AS avg_web_paid
FROM base
GROUP BY department, gender, website, warehouse_state, return_reason, profit_category
HAVING SUM(combined_profit) > 5000
ORDER BY total_profit DESC
LIMIT 100
