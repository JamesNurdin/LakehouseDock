WITH sales_base AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ss.ss_sold_time_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ticket_number,
        c.c_birth_year,
        p.p_promo_name,
        p.p_discount_active,
        s.s_store_name,
        s.s_city,
        t.t_shift,
        t.t_second
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN "store" s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
),
agg_sales AS (
    SELECT
        sb.s_store_name,
        sb.p_promo_name,
        sb.t_shift,
        sb.s_city,
        sb.p_discount_active,
        SUM(sb.ss_net_profit) AS total_profit,
        COUNT(DISTINCT sb.ss_ticket_number) AS transaction_cnt,
        AVG(sb.ss_quantity) AS avg_quantity,
        MAX(td2.t_second) AS max_second,
        MIN(c2.c_birth_year) AS youngest_birth_year
    FROM sales_base sb
    JOIN time_dim td2 ON sb.ss_sold_time_sk = td2.t_time_sk
    JOIN time_dim td3 ON sb.ss_sold_time_sk = td3.t_time_sk
    JOIN "store" s2 ON sb.ss_store_sk = s2.s_store_sk
    JOIN promotion p2 ON sb.ss_promo_sk = p2.p_promo_sk
    JOIN customer c2 ON sb.ss_customer_sk = c2.c_customer_sk
    GROUP BY
        sb.s_store_name,
        sb.p_promo_name,
        sb.t_shift,
        sb.s_city,
        sb.p_discount_active
)
SELECT
    a.s_store_name,
    a.p_promo_name,
    a.t_shift,
    a.s_city,
    a.p_discount_active,
    a.total_profit,
    a.transaction_cnt,
    a.avg_quantity,
    a.max_second,
    a.youngest_birth_year,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_name ORDER BY a.total_profit DESC) AS profit_rank
FROM agg_sales a
ORDER BY a.total_profit DESC
LIMIT 50
