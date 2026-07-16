WITH store_year_metrics AS (
    SELECT
        store.s_store_id,
        store.s_store_name,
        date_dim.d_year,
        SUM(store_sales.ss_quantity) AS total_sales_quantity,
        SUM(store_sales.ss_net_profit) AS total_net_profit,
        SUM(catalog_returns.cr_net_loss) AS total_net_loss,
        SUM(catalog_returns.cr_return_quantity) AS total_return_quantity,
        SUM(catalog_returns.cr_return_amount) AS total_return_amount
    FROM catalog_returns
    JOIN date_dim
        ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
    JOIN store
        ON store.s_closed_date_sk = date_dim.d_date_sk
    JOIN store_sales
        ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
        AND store_sales.ss_store_sk = store.s_store_sk
    GROUP BY
        store.s_store_id,
        store.s_store_name,
        date_dim.d_year
)
SELECT
    s_year.s_store_id,
    s_year.s_store_name,
    s_year.d_year,
    s_year.total_sales_quantity,
    s_year.total_net_profit,
    s_year.total_net_loss,
    s_year.total_return_quantity,
    s_year.total_return_amount,
    (s_year.total_net_profit - s_year.total_net_loss) AS net_profit_after_returns,
    CASE
        WHEN s_year.total_sales_quantity = 0 THEN 0
        ELSE s_year.total_return_quantity * 1.0 / s_year.total_sales_quantity
    END AS return_quantity_ratio,
    RANK() OVER (
        PARTITION BY s_year.d_year
        ORDER BY (s_year.total_net_profit - s_year.total_net_loss) DESC
    ) AS profit_rank_within_year
FROM store_year_metrics AS s_year
WHERE s_year.total_sales_quantity > 0
ORDER BY s_year.d_year, profit_rank_within_year
LIMIT 200
