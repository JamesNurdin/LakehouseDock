WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales_transactions
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_return_transactions
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
)
SELECT
    COALESCE(sales_agg.s_store_id, returns_agg.s_store_id) AS store_id,
    COALESCE(sales_agg.s_store_name, returns_agg.s_store_name) AS store_name,
    COALESCE(sales_agg.d_year, returns_agg.d_year) AS year,
    COALESCE(sales_agg.d_month_seq, returns_agg.d_month_seq) AS month_seq,
    sales_agg.total_sales_amount,
    returns_agg.total_return_amount,
    sales_agg.total_sales_profit,
    returns_agg.total_return_loss,
    (COALESCE(sales_agg.total_sales_profit, 0) - COALESCE(returns_agg.total_return_loss, 0)) AS net_profit_after_returns,
    sales_agg.num_sales_transactions,
    returns_agg.num_return_transactions
FROM sales_agg
FULL OUTER JOIN returns_agg
    ON sales_agg.s_store_id = returns_agg.s_store_id
   AND sales_agg.d_year = returns_agg.d_year
   AND sales_agg.d_month_seq = returns_agg.d_month_seq
ORDER BY net_profit_after_returns DESC
LIMIT 100
