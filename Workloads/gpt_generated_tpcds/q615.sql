WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        sum(ss.ss_net_profit) AS total_sales_profit,
        sum(ss.ss_ext_discount_amt) AS total_discount_amount,
        sum(ss.ss_quantity) AS total_quantity,
        sum(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        d.d_year,
        d.d_moy,
        sum(sr.sr_net_loss) AS total_return_loss,
        sum(sr.sr_return_quantity) AS total_return_quantity,
        sum(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, d.d_year, d.d_moy
)
SELECT
    sales.s_store_name,
    sales.d_year,
    sales.d_moy,
    sales.total_sales_profit,
    coalesce(returns.total_return_loss, 0) AS total_return_loss,
    sales.total_sales_profit - coalesce(returns.total_return_loss, 0) AS net_profit_after_returns,
    sales.total_discount_amount,
    sales.total_quantity,
    CASE WHEN sales.total_quantity > 0 THEN sales.total_discount_amount / sales.total_quantity ELSE 0 END AS avg_discount_per_unit,
    sales.total_net_paid,
    returns.total_return_quantity,
    returns.total_return_amount
FROM sales_agg sales
LEFT JOIN returns_agg returns
    ON sales.s_store_sk = returns.s_store_sk
    AND sales.d_year = returns.d_year
    AND sales.d_moy = returns.d_moy
ORDER BY net_profit_after_returns DESC
LIMIT 10
