WITH filtered_sales AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(c.c_email_address, '[A-Za-z0-9._%+-]+@example\\.com')
      AND ca.ca_street_type LIKE '%Ave%'
)
SELECT
    s.s_store_id,
    s.s_store_name,
    substring(s.s_store_name, 1, 3) AS store_prefix,
    t.t_hour,
    COUNT(*) AS sales_cnt,
    SUM(fs.ss_net_paid) AS total_paid,
    SUM(fs.ss_net_profit) AS total_profit,
    CASE WHEN SUM(fs.ss_net_profit) > 1000 THEN 'High' ELSE 'Normal' END AS profit_category
FROM filtered_sales fs
JOIN time_dim t ON fs.ss_sold_time_sk = t.t_time_sk
JOIN store s ON fs.ss_store_sk = s.s_store_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    substring(s.s_store_name, 1, 3),
    t.t_hour
ORDER BY total_profit DESC
LIMIT 100
