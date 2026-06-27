WITH sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        i.i_category,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        i.i_category
),
returns AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        i.i_category,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        i.i_category
)
SELECT
    sales.s_store_name,
    sales.d_year,
    sales.d_moy,
    sales.i_category,
    sales.total_sales,
    sales.total_profit,
    sales.total_quantity,
    COALESCE(returns.total_return_qty, 0) AS total_return_qty,
    COALESCE(returns.total_return_loss, 0) AS total_return_loss,
    sales.total_profit - COALESCE(returns.total_return_loss, 0) AS net_profit_after_returns
FROM sales
LEFT JOIN returns
    ON sales.s_store_sk = returns.s_store_sk
   AND sales.d_year = returns.d_year
   AND sales.d_moy = returns.d_moy
   AND sales.i_category = returns.i_category
ORDER BY net_profit_after_returns DESC
LIMIT 100
