WITH sales_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY ss.ss_item_sk, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY sr.sr_item_sk, d.d_year, d.d_month_seq
)
SELECT
    i.i_category,
    s.d_year,
    s.d_month_seq,
    s.total_sales_amount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) / NULLIF(s.total_sales_amount - COALESCE(r.total_return_amount, 0), 0) AS profit_margin
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.item_sk = r.item_sk
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
JOIN item i
    ON s.item_sk = i.i_item_sk
ORDER BY i.i_category, s.d_year, s.d_month_seq
