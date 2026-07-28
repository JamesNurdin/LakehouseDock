SELECT DISTINCT
    store_id,
    year,
    total_sales,
    total_profit,
    profit_category,
    promo_channel
FROM (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE
            WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High'
            WHEN SUM(ss.ss_net_profit) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        'Email' AS promo_channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
    GROUP BY s.s_store_id, d.d_year

    UNION ALL

    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE
            WHEN SUM(ss.ss_net_profit) > 80000 THEN 'High'
            WHEN SUM(ss.ss_net_profit) > 30000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        'TV' AS promo_channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
    GROUP BY s.s_store_id, d.d_year
) AS combined
ORDER BY total_sales DESC
LIMIT 100
