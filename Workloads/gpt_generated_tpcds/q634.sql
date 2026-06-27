WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(sr.sr_return_quantity) AS total_quantity_returned,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_moy
)
SELECT
    sales.s_store_name,
    sales.s_store_sk,
    CONCAT(CAST(sales.d_year AS VARCHAR), '-', LPAD(CAST(sales.d_moy AS VARCHAR), 2, '0')) AS year_month,
    sales.total_quantity_sold,
    COALESCE(returns.total_quantity_returned, 0) AS total_quantity_returned,
    CASE WHEN sales.total_quantity_sold > 0
         THEN COALESCE(returns.total_quantity_returned, 0) * 1.0 / sales.total_quantity_sold
         ELSE 0
    END AS return_rate,
    sales.total_sales_amount,
    COALESCE(returns.total_return_amount, 0) AS total_return_amount,
    sales.total_net_profit - COALESCE(returns.total_net_loss, 0) AS net_profit_after_returns
FROM sales_agg sales
LEFT JOIN returns_agg returns
    ON sales.s_store_sk = returns.s_store_sk
   AND sales.d_year = returns.d_year
   AND sales.d_moy = returns.d_moy
ORDER BY sales.s_store_name, year_month
