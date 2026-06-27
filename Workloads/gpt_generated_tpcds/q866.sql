WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_return_customers
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
),
combined AS (
    SELECT
        s.s_store_name,
        s.d_year,
        s.d_month_seq,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        s.total_sales - COALESCE(r.total_returns, 0) AS net_revenue,
        s.total_profit,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
        s.distinct_customers,
        COALESCE(r.distinct_return_customers, 0) AS distinct_return_customers
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.s_store_sk = r.s_store_sk
        AND s.d_year = r.d_year
        AND s.d_month_seq = r.d_month_seq
    WHERE s.d_year = 2001
)
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    total_sales,
    total_returns,
    net_revenue,
    total_profit,
    total_return_loss,
    net_profit,
    distinct_customers,
    distinct_return_customers,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY net_profit DESC) AS profit_rank
FROM combined
ORDER BY net_profit DESC
LIMIT 10
