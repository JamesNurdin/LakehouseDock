WITH sales_by_store AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        s.s_city,
        p.p_promo_id,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        CASE
            WHEN ss.ss_net_profit > 0 THEN 'POSITIVE'
            ELSE 'NON_POSITIVE'
        END AS profit_flag
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_state IN ('CA', 'TX', 'NY')
      AND s.s_city NOT IN ('Springfield', 'Riverside')
      AND s.s_rec_end_date >= DATE '2000-01-01'
      AND p.p_channel_tv = 'Y'
      AND p.p_channel_email = 'N'
      AND ss.ss_ext_sales_price > 1000
)
SELECT
    state,
    city,
    profit_flag,
    SUM(total_quantity) AS total_qty,
    SUM(total_sales)   AS total_sales,
    AVG(avg_profit)    AS avg_profit,
    COUNT(DISTINCT store_id) AS distinct_stores,
    (SELECT AVG(p_cost) FROM promotion WHERE p_discount_active = 'Y') AS avg_active_promo_cost
FROM (
    SELECT
        s_state AS state,
        s_city  AS city,
        profit_flag,
        SUM(ss_quantity)        AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit)      AS avg_profit,
        s_store_id              AS store_id
    FROM sales_by_store
    WHERE profit_flag = 'POSITIVE'
    GROUP BY ROLLUP (s_state, s_city, profit_flag, s_store_id)

    UNION ALL

    SELECT
        s_state AS state,
        s_city  AS city,
        profit_flag,
        SUM(ss_quantity)        AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit)      AS avg_profit,
        s_store_id              AS store_id
    FROM sales_by_store
    WHERE profit_flag = 'NON_POSITIVE'
    GROUP BY ROLLUP (s_state, s_city, profit_flag, s_store_id)
) agg
GROUP BY ROLLUP (state, city, profit_flag)
HAVING SUM(total_sales) > 5000
ORDER BY state, city, profit_flag
LIMIT 100
