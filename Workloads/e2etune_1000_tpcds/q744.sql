WITH store_monthly_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS num_sales,
        SUM(CASE WHEN p.p_channel_email = 'Y' THEN ss.ss_net_paid ELSE 0 END) AS email_promo_net_paid,
        SUM(CASE WHEN p.p_channel_email = 'Y' THEN 1 ELSE 0 END) AS email_promo_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_state = 'CA'
      AND d.d_year = 2002
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
),
store_monthly_lag AS (
    SELECT
        sm.s_store_sk,
        sm.s_store_name,
        sm.d_year,
        sm.d_month_seq,
        sm.total_net_paid,
        sm.total_profit,
        sm.avg_discount,
        sm.email_promo_net_paid,
        sm.email_promo_cnt,
        LAG(sm.total_profit) OVER (PARTITION BY sm.s_store_sk ORDER BY sm.d_month_seq) AS prev_month_profit
    FROM store_monthly_sales sm
)
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    total_net_paid,
    total_profit,
    avg_discount,
    email_promo_net_paid,
    email_promo_cnt,
    prev_month_profit,
    (total_profit - prev_month_profit) / NULLIF(prev_month_profit, 0) AS profit_change_ratio,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank_year
FROM store_monthly_lag
WHERE prev_month_profit IS NOT NULL
ORDER BY d_year, profit_rank_year
LIMIT 100
