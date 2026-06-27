WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_transactions
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    COALESCE(sa.total_sales, 0) AS total_sales,
    COALESCE(sa.total_profit, 0) AS total_profit,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    CASE
        WHEN COALESCE(sa.total_sales, 0) = 0 THEN 0
        ELSE (COALESCE(ra.total_return_amount, 0) / COALESCE(sa.total_sales, 0)) * 100
    END AS return_rate_percent,
    ROW_NUMBER() OVER (ORDER BY COALESCE(sa.total_sales, 0) DESC) AS sales_rank
FROM store s
LEFT JOIN sales_agg sa
    ON s.s_store_sk = sa.s_store_sk
LEFT JOIN returns_agg ra
    ON s.s_store_sk = ra.s_store_sk
WHERE s.s_state IN ('CA', 'TX', 'NY')
ORDER BY total_sales DESC
LIMIT 20
