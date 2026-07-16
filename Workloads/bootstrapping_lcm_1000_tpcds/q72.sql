WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sold.d_current_month,
        d_sold.d_year,
        p.p_promo_name,
        COUNT(*) AS num_sales,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE s.s_closed_date_sk IS NULL OR s.s_closed_date_sk > d_sold.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sold.d_current_month,
        d_sold.d_year,
        p.p_promo_name,
        d_promo_start.d_date,
        d_promo_end.d_date
)
SELECT
    s_store_id,
    s_store_name,
    d_current_month,
    d_year,
    p_promo_name,
    num_sales,
    total_sales,
    total_net_profit,
    total_discount,
    avg_sales_price,
    promo_duration_days,
    RANK() OVER (PARTITION BY d_year, d_current_month ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY d_year, d_current_month, profit_rank
LIMIT 200
