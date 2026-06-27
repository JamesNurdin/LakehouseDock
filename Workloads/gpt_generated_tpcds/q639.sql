WITH sales AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
returns AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_quantity) AS total_quantity_returned,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
)
SELECT
    st.s_store_id,
    st.s_store_name,
    sales.d_year,
    sales.d_month_seq,
    sales.total_quantity_sold,
    COALESCE(returns.total_quantity_returned, 0) AS total_quantity_returned,
    sales.total_sales_amount,
    COALESCE(returns.total_return_amount, 0) AS total_return_amount,
    sales.total_net_paid,
    COALESCE(returns.total_net_loss, 0) AS total_net_loss,
    (sales.total_net_profit - COALESCE(returns.total_net_loss, 0)) AS net_profit_after_returns,
    RANK() OVER (
        PARTITION BY sales.d_year, sales.d_month_seq
        ORDER BY (sales.total_net_profit - COALESCE(returns.total_net_loss, 0)) DESC
    ) AS profit_rank
FROM sales
LEFT JOIN returns
    ON sales.store_sk = returns.store_sk
    AND sales.d_year = returns.d_year
    AND sales.d_month_seq = returns.d_month_seq
JOIN store st
    ON sales.store_sk = st.s_store_sk
ORDER BY sales.d_year, sales.d_month_seq, profit_rank
