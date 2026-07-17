WITH monthly_store_profit AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(CASE WHEN ib.ib_lower_bound >= 80000 THEN ss.ss_net_profit ELSE 0 END) AS high_income_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
)
SELECT
    m.s_store_sk,
    m.s_store_name,
    m.d_year,
    m.d_month_seq,
    m.total_net_profit,
    m.high_income_net_profit,
    CASE
        WHEN m.total_net_profit >= 100000 THEN 'High'
        WHEN m.total_net_profit >= 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY m.d_year, m.d_month_seq ORDER BY m.total_net_profit DESC) AS profit_rank,
    AVG(m.total_net_profit) OVER (
        PARTITION BY m.s_store_sk
        ORDER BY m.d_year, m.d_month_seq
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3m_net_profit
FROM monthly_store_profit m
ORDER BY m.d_year, m.d_month_seq, profit_rank
