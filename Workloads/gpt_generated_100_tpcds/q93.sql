WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_quantity) AS total_sales_qty,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amt
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
)
SELECT
    s.d_year,
    s.d_month_seq,
    st.s_store_id,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
    s.total_sales_qty,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    s.total_sales_qty - COALESCE(r.total_return_qty, 0) AS net_quantity,
    s.total_discount_amt / NULLIF(s.total_sales_qty, 0) AS avg_discount,
    RANK() OVER (ORDER BY s.total_sales_profit - COALESCE(r.total_return_loss, 0) DESC) AS profit_rank
FROM sales_agg s
JOIN store st
  ON s.store_sk = st.s_store_sk
LEFT JOIN returns_agg r
  ON s.store_sk = r.store_sk
  AND s.d_year = r.d_year
  AND s.d_month_seq = r.d_month_seq
ORDER BY net_profit DESC
LIMIT 20
