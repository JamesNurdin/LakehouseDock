WITH intersected_customers AS (
    SELECT ss_customer_sk AS customer_sk
    FROM store_sales
    WHERE ss_sales_price > 50
    INTERSECT
    SELECT ws_bill_customer_sk
    FROM web_sales
    WHERE ws_sales_price > 50
),
joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.s_store_name,
        s.s_state,
        ca.ca_zip,
        sm.sm_type,
        w.web_name,
        t.t_hour,
        ss.ss_ext_sales_price AS ss_sales,
        ws.ws_ext_sales_price AS ws_sales,
        ss.ss_net_profit + ws.ws_net_profit AS profit
    FROM intersected_customers ic
    JOIN customer c ON ic.customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN "store" s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
        AND ca.ca_zip LIKE '8%'
        AND s.s_state = 'CA'
        AND t.t_hour BETWEEN 9 AND 17
),
aggregated AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        s_store_name,
        sm_type,
        web_name,
        t_hour,
        SUM(ss_sales) AS store_sales_total,
        SUM(ws_sales) AS web_sales_total,
        SUM(profit) AS total_profit
    FROM joined_data
    GROUP BY GROUPING SETS (
        (c_customer_id, c_first_name, c_last_name, s_store_name, sm_type, web_name, t_hour),
        (c_customer_id, c_first_name, c_last_name, s_store_name, sm_type, web_name),
        (c_customer_id, c_first_name, c_last_name, s_store_name),
        ()
    )
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    s_store_name,
    sm_type,
    web_name,
    t_hour,
    store_sales_total,
    web_sales_total,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY total_profit DESC) AS sales_rank,
    LAG(total_profit) OVER (PARTITION BY c_customer_id ORDER BY t_hour) AS prev_hour_profit,
    CASE
        WHEN total_profit > 10000 THEN 'HIGH'
        WHEN total_profit > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM aggregated
ORDER BY total_profit DESC
OFFSET 0 LIMIT 100
