WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_date,
        d.d_year,
        t.t_shift,
        p.p_discount_active,
        s.s_store_name,
        s.s_tax_percentage
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
)
SELECT
    u.s_store_name,
    u.d_date,
    u.total_net_paid,
    u.total_net_profit,
    u.profit_flag,
    u.store_rank
FROM (
    SELECT
        b.s_store_name,
        b.d_date,
        SUM(b.ss_net_paid) AS total_net_paid,
        SUM(b.ss_net_profit) AS total_net_profit,
        CASE WHEN SUM(b.ss_net_profit) > 10000 THEN 'Profit > 10k' ELSE 'Profit <= 10k' END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY b.d_date ORDER BY SUM(b.ss_net_paid) DESC) AS store_rank
    FROM base_sales b
    WHERE b.t_shift = 'first'
    GROUP BY b.s_store_name, b.d_date
    HAVING SUM(b.ss_net_paid) > 2000

    UNION ALL

    SELECT
        b.s_store_name,
        b.d_date,
        SUM(b.ss_net_paid) AS total_net_paid,
        SUM(b.ss_net_profit) AS total_net_profit,
        CASE WHEN SUM(b.ss_net_profit) > 10000 THEN 'Profit > 10k' ELSE 'Profit <= 10k' END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY b.d_date ORDER BY SUM(b.ss_net_paid) DESC) AS store_rank
    FROM base_sales b
    WHERE b.t_shift = 'second'
    GROUP BY b.s_store_name, b.d_date
    HAVING SUM(b.ss_net_paid) > 2000
) AS u
ORDER BY u.d_date, u.total_net_paid DESC
LIMIT 100
