WITH sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
),
returns AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(r.sr_net_loss) AS total_net_loss,
        SUM(r.sr_return_quantity) AS total_return_quantity,
        SUM(r.sr_return_amt) AS total_return_amount
    FROM store_returns r
    JOIN store s ON r.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON r.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
)
SELECT
    sales.s_store_name,
    sales.d_year,
    sales.d_month_seq,
    sales.total_net_profit,
    COALESCE(returns.total_net_loss, 0) AS total_net_loss,
    sales.total_net_profit - COALESCE(returns.total_net_loss, 0) AS net_profit_after_returns,
    sales.total_quantity,
    COALESCE(returns.total_return_quantity, 0) AS total_return_quantity,
    CASE WHEN sales.total_quantity > 0 THEN COALESCE(returns.total_return_quantity, 0) * 100.0 / sales.total_quantity ELSE 0 END AS return_rate_percent,
    sales.total_sales_amount,
    sales.total_discount_amount,
    CASE WHEN sales.total_sales_amount > 0 THEN sales.total_discount_amount * 100.0 / sales.total_sales_amount ELSE 0 END AS discount_rate_percent
FROM sales
LEFT JOIN returns
    ON sales.s_store_sk = returns.s_store_sk
    AND sales.d_year = returns.d_year
    AND sales.d_month_seq = returns.d_month_seq
ORDER BY sales.total_net_profit DESC
LIMIT 100
