WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_net_loss) AS total_return_net_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, d.d_year, d.d_month_seq
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.d_year,
    sa.d_month_seq,
    sa.total_sales_amount,
    sa.total_quantity_sold,
    CASE WHEN sa.total_sales_amount = 0 THEN 0
         ELSE sa.total_discount_amount / sa.total_sales_amount
    END AS discount_pct,
    sa.total_net_profit,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(ra.total_return_net_loss, 0) AS total_return_net_loss,
    sa.total_net_profit - COALESCE(ra.total_return_net_loss, 0) AS net_profit_after_returns
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_id = ra.s_store_id
   AND sa.d_year = ra.d_year
   AND sa.d_month_seq = ra.d_month_seq
ORDER BY sa.d_year, sa.d_month_seq, sa.s_store_id
