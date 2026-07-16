WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy AS month_of_year,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy AS month_of_year,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_moy
)
SELECT
    sa.s_store_name,
    sa.d_year,
    sa.month_of_year,
    sa.total_sales_profit,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    sa.total_sales_profit - COALESCE(ra.total_return_loss, 0) AS net_profit,
    CASE
        WHEN sa.total_sales_profit > 0 THEN CAST(COALESCE(ra.total_return_loss, 0) AS double) / CAST(sa.total_sales_profit AS double)
        ELSE NULL
    END AS return_loss_ratio
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
    AND sa.d_year = ra.d_year
    AND sa.month_of_year = ra.month_of_year
ORDER BY net_profit DESC
LIMIT 100
