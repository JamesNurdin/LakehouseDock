WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_moy,
        SUM(ss.ss_quantity) AS total_sales_qty,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        d.d_moy,
        SUM(sr.sr_return_quantity) AS total_returns_qty,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns_amount,
        SUM(sr.sr_net_loss) AS total_returns_net_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_store_sk, d.d_year, d.d_moy
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    COALESCE(sales.d_year, returns.d_year) AS year,
    COALESCE(sales.d_moy, returns.d_moy) AS month,
    COALESCE(sales.total_sales_qty, 0) AS total_sales_qty,
    COALESCE(sales.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(sales.total_discount_amount, 0) AS total_discount_amount,
    COALESCE(sales.total_net_paid, 0) AS total_net_paid,
    COALESCE(sales.total_net_profit, 0) AS total_net_profit,
    COALESCE(returns.total_returns_qty, 0) AS total_returns_qty,
    COALESCE(returns.total_returns_amount, 0) AS total_returns_amount,
    COALESCE(returns.total_returns_net_loss, 0) AS total_returns_net_loss,
    COALESCE(sales.total_sales_amount, 0) - COALESCE(returns.total_returns_amount, 0) AS net_sales_amount,
    COALESCE(sales.total_net_profit, 0) - COALESCE(returns.total_returns_net_loss, 0) AS net_profit_after_returns,
    CASE WHEN COALESCE(sales.total_sales_amount, 0) = 0 THEN 0
         ELSE COALESCE(sales.total_discount_amount, 0) / COALESCE(sales.total_sales_amount, 1)
    END AS discount_rate
FROM sales_agg sales
FULL OUTER JOIN returns_agg returns
    ON sales.ss_store_sk = returns.sr_store_sk
    AND sales.d_year = returns.d_year
    AND sales.d_moy = returns.d_moy
JOIN store s
    ON COALESCE(sales.ss_store_sk, returns.sr_store_sk) = s.s_store_sk
WHERE s.s_state = 'CA'
ORDER BY net_sales_amount DESC
LIMIT 100
