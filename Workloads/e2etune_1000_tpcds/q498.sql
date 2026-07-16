WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        t.t_hour AS hour_of_day,
        SUM(ss.ss_net_paid) AS total_sales_net_paid,
        SUM(ss.ss_net_profit) AS total_sales_net_profit
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_state IN ('CA','TX','NY')
      AND s.s_rec_start_date >= DATE '2000-01-01'
      AND s.s_rec_end_date <= DATE '2000-12-31'
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, t.t_hour
),
returns_agg AS (
    SELECT
        s.s_store_id,
        t.t_hour AS hour_of_day,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE s.s_state IN ('CA','TX','NY')
      AND s.s_rec_start_date >= DATE '2000-01-01'
      AND s.s_rec_end_date <= DATE '2000-12-31'
    GROUP BY s.s_store_id, t.t_hour
),
store_total AS (
    SELECT
        sa.s_store_id,
        SUM(sa.total_sales_net_profit) - COALESCE(SUM(ra.total_return_amount), 0) AS total_net_profit
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.s_store_id = ra.s_store_id
    GROUP BY sa.s_store_id
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.s_state,
    sa.hour_of_day,
    sa.total_sales_net_paid,
    sa.total_sales_net_profit,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    (sa.total_sales_net_profit - COALESCE(ra.total_return_amount, 0)) AS net_profit_after_returns,
    SUM(sa.total_sales_net_profit - COALESCE(ra.total_return_amount, 0)) OVER (PARTITION BY sa.s_store_id ORDER BY sa.hour_of_day) AS cum_net_profit,
    RANK() OVER (PARTITION BY sa.s_store_id ORDER BY (sa.total_sales_net_profit - COALESCE(ra.total_return_amount, 0)) DESC) AS hour_profit_rank,
    RANK() OVER (ORDER BY st.total_net_profit DESC) AS store_profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_id = ra.s_store_id
   AND sa.hour_of_day = ra.hour_of_day
JOIN store_total st
    ON sa.s_store_id = st.s_store_id
WHERE (sa.total_sales_net_profit - COALESCE(ra.total_return_amount, 0)) > 0
ORDER BY net_profit_after_returns DESC, cum_net_profit DESC
LIMIT 100
