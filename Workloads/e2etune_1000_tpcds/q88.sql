WITH sales_agg AS (
    SELECT
        ca.ca_city AS city,
        CASE
            WHEN p.p_channel_email = 'Y' THEN 'Email'
            WHEN p.p_channel_tv = 'Y' THEN 'TV'
            WHEN p.p_channel_radio = 'Y' THEN 'Radio'
            WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
            WHEN p.p_channel_dmail = 'Y' THEN 'DirectMail'
            ELSE 'Other'
        END AS promo_channel,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2458849 AND 2459150
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY 1, 2
)
SELECT
    city,
    promo_channel,
    order_count,
    total_net_paid,
    total_net_profit,
    avg_sales_price,
    RANK() OVER (PARTITION BY promo_channel ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
WHERE total_net_profit > 10000
ORDER BY promo_channel, profit_rank
LIMIT 200
