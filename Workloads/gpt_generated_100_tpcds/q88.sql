WITH sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
),
returns AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
),
combined AS (
    SELECT
        sales.s_store_name,
        sales.d_year,
        sales.d_month_seq,
        sales.total_sales_amount,
        sales.total_sales_profit,
        COALESCE(returns.total_return_loss, 0) AS total_return_loss,
        sales.total_sales_profit - COALESCE(returns.total_return_loss, 0) AS net_contribution
    FROM sales
    LEFT JOIN returns
        ON sales.s_store_sk = returns.s_store_sk
        AND sales.d_year = returns.d_year
        AND sales.d_month_seq = returns.d_month_seq
)
SELECT
    c.s_store_name,
    c.d_year,
    c.d_month_seq,
    c.total_sales_amount,
    c.total_sales_profit,
    c.total_return_loss,
    c.net_contribution,
    RANK() OVER (PARTITION BY c.d_year, c.d_month_seq ORDER BY c.net_contribution DESC) AS month_store_rank
FROM combined c
ORDER BY c.net_contribution DESC
LIMIT 20
