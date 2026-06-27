WITH sales_agg AS (
    SELECT
        s.s_store_id,
        date_trunc('month', d.d_date) AS month,
        sum(ss.ss_net_profit) AS total_profit,
        sum(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
    GROUP BY s.s_store_id, date_trunc('month', d.d_date)
),
returns_agg AS (
    SELECT
        s.s_store_id,
        date_trunc('month', d.d_date) AS month,
        sum(sr.sr_net_loss) AS total_return_loss,
        sum(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
    GROUP BY s.s_store_id, date_trunc('month', d.d_date)
)
SELECT
    coalesce(sa.s_store_id, ra.s_store_id) AS store_id,
    coalesce(sa.month, ra.month) AS month,
    coalesce(sa.total_profit, 0) AS total_profit,
    coalesce(ra.total_return_loss, 0) AS total_return_loss,
    coalesce(sa.total_sales, 0) AS total_sales,
    coalesce(ra.total_return_amount, 0) AS total_return_amount,
    (coalesce(sa.total_profit, 0) - coalesce(ra.total_return_loss, 0)) AS net_profit_after_returns
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.s_store_id = ra.s_store_id
   AND sa.month = ra.month
ORDER BY net_profit_after_returns DESC
LIMIT 100
