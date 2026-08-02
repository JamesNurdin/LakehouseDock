WITH email_parts AS (
    SELECT 
        c.c_customer_sk,
        SPLIT(c.c_email_address, '@') AS email_parts,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
    FROM customer c
),
sales_with_web AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ca.ca_state,
        sm.sm_carrier,
        sm.sm_type,
        w.w_warehouse_name,
        ep.email_parts,
        CONCAT(ep.c_first_name, ' ', ep.c_last_name) AS full_name,
        wp.wp_url,
        SUBSTRING(wp.wp_url, 1, 30) AS url_prefix
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN email_parts ep ON c.c_customer_sk = ep.c_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE sm.sm_carrier LIKE 'B%'
      AND REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND (wp.wp_url IS NULL OR REGEXP_LIKE(wp.wp_url, '^https?://.*example\\.com/.*'))
)
SELECT
    sw.cs_sold_date_sk,
    sw.ca_state,
    sw.sm_carrier,
    sw.w_warehouse_name,
    part AS email_part,
    MAX(sw.url_prefix) AS url_prefix,
    COUNT(*) AS order_cnt,
    SUM(sw.cs_ext_sales_price) AS total_sales,
    SUM(sw.cs_net_profit) AS total_profit,
    CASE WHEN SUM(sw.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status
FROM sales_with_web sw
CROSS JOIN UNNEST(sw.email_parts) AS t (part)
GROUP BY GROUPING SETS (
    (sw.cs_sold_date_sk, sw.ca_state, sw.sm_carrier, sw.w_warehouse_name, part),
    (sw.cs_sold_date_sk, sw.ca_state, sw.sm_carrier, sw.w_warehouse_name),
    (sw.cs_sold_date_sk, sw.ca_state),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
