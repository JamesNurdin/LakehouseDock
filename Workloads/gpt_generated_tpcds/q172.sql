WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq
),
returns_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY
        s.s_store_id,
        d.d_year,
        d.d_month_seq
),
combined AS (
    SELECT
        sa.s_store_id,
        sa.s_store_name,
        sa.d_year,
        sa.d_month_seq,
        sa.total_sales_amount,
        sa.total_sales_quantity,
        sa.total_sales_profit,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
        sa.distinct_customers
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.s_store_id = ra.s_store_id
        AND sa.d_year = ra.d_year
        AND sa.d_month_seq = ra.d_month_seq
)
SELECT
    c.s_store_id,
    c.s_store_name,
    c.d_year,
    c.d_month_seq,
    c.total_sales_amount,
    LAG(c.total_sales_amount) OVER (PARTITION BY c.s_store_id ORDER BY c.d_year, c.d_month_seq) AS prev_month_sales,
    CASE
        WHEN LAG(c.total_sales_amount) OVER (PARTITION BY c.s_store_id ORDER BY c.d_year, c.d_month_seq) = 0 THEN NULL
        ELSE (c.total_sales_amount - LAG(c.total_sales_amount) OVER (PARTITION BY c.s_store_id ORDER BY c.d_year, c.d_month_seq)) / LAG(c.total_sales_amount) OVER (PARTITION BY c.s_store_id ORDER BY c.d_year, c.d_month_seq) * 100
    END AS sales_growth_pct,
    c.total_sales_quantity,
    c.total_sales_profit,
    c.total_return_amount,
    c.total_return_quantity,
    c.total_return_loss,
    c.net_profit_after_returns,
    CASE
        WHEN c.total_sales_amount = 0 THEN NULL
        ELSE c.net_profit_after_returns / c.total_sales_amount * 100
    END AS net_profit_margin_pct,
    c.distinct_customers
FROM combined c
ORDER BY
    c.s_store_id,
    c.d_year DESC,
    c.d_month_seq DESC
