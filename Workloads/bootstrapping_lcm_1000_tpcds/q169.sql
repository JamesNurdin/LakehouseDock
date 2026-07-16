WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sales.d_date,
        d_sales.d_year,
        d_sales.d_month_seq,
        t.t_hour,
        t.t_meal_time,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    LEFT JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    WHERE d_sales.d_date >= DATE '2023-01-01'
      AND d_sales.d_date <= DATE '2023-12-31'
      AND d_sales.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
      AND (s.s_closed_date_sk IS NULL OR d_sales.d_date < d_store_closed.d_date)
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sales.d_date,
        d_sales.d_year,
        d_sales.d_month_seq,
        t.t_hour,
        t.t_meal_time,
        p.p_promo_name
)
SELECT
    s_store_id,
    s_store_name,
    d_date,
    d_year,
    d_month_seq,
    t_hour,
    t_meal_time,
    p_promo_name,
    total_sales,
    total_profit,
    transaction_count,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
