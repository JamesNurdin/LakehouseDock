WITH sales_data AS (
    SELECT
        concat(s.s_store_name, ' (', s.s_city, ')') AS store_label,
        p.p_promo_name AS promo_name,
        regexp_extract(c.c_email_address, '@([^@]+)$', 1) AS email_domain,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '(?i)premium|deluxe')
      AND s.s_city LIKE 'San%'
      AND regexp_like(p.p_promo_name, '(?i)holiday|summer')
)
SELECT
    store_label,
    promo_name,
    email_domain,
    SUM(quantity) AS total_quantity,
    SUM(net_profit) AS total_net_profit,
    CASE
        WHEN SUM(net_profit) > 100000 THEN 'High'
        WHEN SUM(net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM sales_data
GROUP BY store_label, promo_name, email_domain
ORDER BY total_net_profit DESC
LIMIT 100
