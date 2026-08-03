WITH base_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        td.t_hour,
        ca.ca_state,
        p.p_promo_name,
        p.p_discount_active,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        wp.wp_url
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '\\.com$')
      AND (ca.ca_state LIKE 'C%' OR ca.ca_state LIKE 'N%')
      AND (wp.wp_url IS NULL OR regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) LIKE '%example%')
),
filtered_sales AS (
    SELECT
        ss_ticket_number,
        ss_net_paid,
        ss_net_profit,
        ca_state,
        p_promo_name,
        t_hour
    FROM base_sales bs
    WHERE NOT EXISTS (
        SELECT 1 FROM store_returns sr
        WHERE sr.sr_ticket_number = bs.ss_ticket_number
    )
)
SELECT
    ca_state,
    p_promo_name,
    t_hour,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CASE WHEN SUM(ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
FROM filtered_sales
GROUP BY CUBE (ca_state, p_promo_name, t_hour)
ORDER BY total_net_paid DESC
LIMIT 100
