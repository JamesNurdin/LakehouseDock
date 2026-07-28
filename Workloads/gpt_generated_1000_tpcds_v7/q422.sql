WITH base AS (
    SELECT
        s.s_division_name,
        p.p_promo_name,
        t.t_hour,
        ss.ss_ext_tax,
        ss.ss_net_profit,
        ss.ss_quantity,
        s.s_state,
        s.s_city,
        s.s_store_name,
        p.p_channel_event,
        p.p_discount_active,
        s.s_rec_end_date,
        t.t_meal_time
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_rec_end_date >= DATE '2000-01-01'
      AND s.s_state = 'CA'
      AND p.p_channel_event = 'Y'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_ext_tax > 0
      AND ss.ss_quantity >= 1
),
agg AS (
    SELECT
        s_division_name AS division_name,
        p_promo_name AS promo_name,
        t_hour AS hour,
        SUM(ss_net_profit) AS total_profit,
        AVG(ss_ext_tax) AS avg_tax,
        COUNT(*) AS sales_cnt
    FROM base
    GROUP BY s_division_name, p_promo_name, t_hour
)
SELECT
    division_name,
    promo_name,
    hour,
    total_profit,
    avg_tax,
    sales_cnt,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER (
        PARTITION BY division_name
        ORDER BY total_profit
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_by_division
FROM agg
ORDER BY total_profit DESC
LIMIT 100
