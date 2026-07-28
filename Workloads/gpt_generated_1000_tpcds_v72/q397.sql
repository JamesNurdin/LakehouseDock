WITH ws_agg AS (
    SELECT
        ws_web_page_sk,
        ws_sold_time_sk,
        SUM(ws_net_paid) AS ws_net_paid_sum,
        COUNT(DISTINCT ws_order_number) AS ws_distinct_orders
    FROM web_sales
    GROUP BY ws_web_page_sk, ws_sold_time_sk
)
SELECT
    cp.cp_catalog_number,
    c_bill.c_customer_id AS billing_customer,
    c_ship.c_customer_id AS shipping_customer,
    s.s_store_name,
    sm.sm_type,
    wp.wp_url,
    t_cs.t_hour AS hour_of_day,
    SUM(cs.cs_net_paid_inc_ship) AS total_catalog_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ws_agg.ws_net_paid_sum) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    (
        SELECT AVG(cs2.cs_net_paid_inc_ship)
        FROM catalog_sales cs2
        WHERE cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
    ) AS avg_catalog_sales_per_page
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_sales ss ON ss.ss_sold_time_sk = t_cs.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN ws_agg ON ws_agg.ws_sold_time_sk = t_cs.t_time_sk
JOIN web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
WHERE t_cs.t_time_sk = t_ss.t_time_sk
  AND t_cs.t_time_sk = t_sr.t_time_sk
  AND cp.cp_department = 'Books'
GROUP BY
    cp.cp_catalog_number,
    c_bill.c_customer_id,
    c_ship.c_customer_id,
    s.s_store_name,
    sm.sm_type,
    wp.wp_url,
    t_cs.t_hour,
    cp.cp_catalog_page_sk
ORDER BY total_catalog_sales DESC
LIMIT 100
