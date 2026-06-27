WITH sales_by_store_month AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        year(d_sales.d_date) AS sales_year,
        month(d_sales.d_date) AS sales_month,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS num_transactions
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_date >= DATE '2000-01-01'
      AND d_sales.d_date < DATE '2001-01-01'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        year(d_sales.d_date),
        month(d_sales.d_date)
),
returns_by_store_month AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        year(d_ret.d_date) AS return_year,
        month(d_ret.d_date) AS return_month,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS num_returns
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_date >= DATE '2000-01-01'
      AND d_ret.d_date < DATE '2001-01-01'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        year(d_ret.d_date),
        month(d_ret.d_date)
)
SELECT
    s.sales_year,
    s.sales_month,
    s.s_store_id,
    s.s_store_name,
    s.total_sales,
    s.total_discount,
    s.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales_after_returns,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_by_store_month s
LEFT JOIN returns_by_store_month r
    ON s.s_store_id = r.s_store_id
   AND s.sales_year = r.return_year
   AND s.sales_month = r.return_month
ORDER BY s.sales_year, s.sales_month, s.total_sales DESC
LIMIT 100
