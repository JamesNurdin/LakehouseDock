WITH high_profit AS (
    SELECT
        c.c_customer_id AS customer_id,
        ca.ca_state AS state,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE 
            WHEN SUM(ss.ss_net_profit) >= 1000 THEN 'HIGH'
            WHEN SUM(ss.ss_net_profit) >= 500 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
      AND ss.ss_ext_tax > 20
    GROUP BY c.c_customer_id, ca.ca_state, p.p_promo_name
    HAVING SUM(ss.ss_ext_sales_price) > 500
),
low_profit AS (
    SELECT
        c.c_customer_id AS customer_id,
        ca.ca_state AS state,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE 
            WHEN SUM(ss.ss_net_profit) >= 1000 THEN 'HIGH'
            WHEN SUM(ss.ss_net_profit) >= 500 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog <> 'N'
      AND ss.ss_ext_tax <= 20
    GROUP BY c.c_customer_id, ca.ca_state, p.p_promo_name
    HAVING SUM(ss.ss_ext_sales_price) > 200
)
SELECT
    customer_id,
    state,
    promo_name,
    total_sales,
    total_profit,
    profit_category,
    LAG(total_profit) OVER (PARTITION BY profit_category ORDER BY total_sales DESC) AS lag_profit,
    SUM(total_profit) OVER (PARTITION BY profit_category ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit
FROM (
    SELECT * FROM high_profit
    UNION ALL
    SELECT * FROM low_profit
) combined
ORDER BY profit_category, total_sales DESC
LIMIT 100
