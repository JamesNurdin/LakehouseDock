WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_moy
),
combined AS (
    SELECT
        sa.s_store_sk,
        sa.s_store_name,
        sa.d_year,
        sa.d_moy,
        sa.total_sales_profit,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.s_store_sk = ra.s_store_sk
        AND sa.d_year = ra.d_year
        AND sa.d_moy = ra.d_moy
)
SELECT
    c.s_store_name,
    c.d_year,
    c.d_moy,
    c.total_sales_profit,
    c.total_return_loss,
    c.net_profit_after_returns,
    RANK() OVER (PARTITION BY c.d_year, c.d_moy ORDER BY c.net_profit_after_returns DESC) AS profit_rank
FROM combined c
ORDER BY c.d_year, c.d_moy, profit_rank
