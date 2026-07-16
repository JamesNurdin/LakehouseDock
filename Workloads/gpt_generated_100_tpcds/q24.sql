WITH sales_by_store_month AS (
    SELECT
        st.s_store_sk,
        st.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_sales_net_profit
    FROM store_sales ss
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY st.s_store_sk, st.s_store_name, d.d_year, d.d_month_seq
),
returns_by_store_month AS (
    SELECT
        st.s_store_sk,
        st.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_returns_net_loss,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY st.s_store_sk, st.s_store_name, d.d_year, d.d_month_seq
)
SELECT
    s.s_store_name,
    s.d_year,
    s.d_month_seq,
    s.total_sales_net_profit,
    COALESCE(r.total_returns_net_loss, 0) AS total_returns_net_loss,
    s.total_sales_net_profit - COALESCE(r.total_returns_net_loss, 0) AS net_profit_after_returns,
    RANK() OVER (
        PARTITION BY s.d_year
        ORDER BY s.total_sales_net_profit - COALESCE(r.total_returns_net_loss, 0) DESC
    ) AS profit_rank_in_year,
    COALESCE(r.return_count, 0) AS return_count
FROM sales_by_store_month s
LEFT JOIN returns_by_store_month r
    ON s.s_store_sk = r.s_store_sk
   AND s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
ORDER BY s.s_store_name, s.d_year, s.d_month_seq
