/*
  Goal: Summarize store and web sales metrics for preferred male customers living in Springfield,
  focusing on sales that occurred during peak hours (09‑17). The query aggregates sales amounts,
  order counts, and average quantities, categorizes customers based on total store sales,
  computes each customer's maximum web sale via a correlated subquery, and compares it to the
  overall average store profit. Results are ordered by store sales descending and limited to the
  top 100 customers.
*/
WITH base AS (
    SELECT
        c.c_customer_id,
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_education_status,
        td.t_hour,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_quantity
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
        AND ws_site.web_state = 'CA'
    WHERE ca.ca_city = 'Springfield'
      AND cd.cd_gender = 'M'
      AND td.t_hour BETWEEN 9 AND 17
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    base.c_customer_id,
    base.ca_city,
    base.ca_state,
    base.cd_gender,
    base.cd_education_status,
    base.t_hour,
    CASE
        WHEN SUM(base.ss_ext_sales_price) > 10000 THEN 'High Store'
        ELSE 'Low Store'
    END AS store_sales_category,
    SUM(base.ss_ext_sales_price) AS total_store_sales,
    SUM(COALESCE(base.ws_ext_sales_price, 0)) AS total_web_sales,
    COUNT(DISTINCT base.ss_ticket_number) AS store_order_count,
    COUNT(DISTINCT base.ws_order_number) AS web_order_count,
    AVG(base.ss_quantity) AS avg_store_quantity,
    MIN(base.ss_ext_sales_price) AS min_store_sale,
    MAX(base.ss_ext_sales_price) AS max_store_sale,
    (
        SELECT MAX(ws2.ws_ext_sales_price)
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_bill_customer_sk = base.c_customer_sk
    ) AS max_web_sale,
    (
        SELECT AVG(ss3.ss_net_profit)
        FROM tpcds.store_sales ss3
    ) AS overall_avg_store_profit
FROM base
GROUP BY
    base.c_customer_id,
    base.c_customer_sk,
    base.ca_city,
    base.ca_state,
    base.cd_gender,
    base.cd_education_status,
    base.t_hour
ORDER BY total_store_sales DESC
LIMIT 100
