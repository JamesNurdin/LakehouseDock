WITH store_sales_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS store_sales_total,
        SUM(ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS store_transactions
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk
),
web_sales_agg AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS web_sales_total,
        SUM(ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws_order_number) AS web_transactions
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
catalog_returns_agg AS (
    SELECT
        cr_returned_date_sk,
        SUM(cr_net_loss) AS total_return_loss
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_date AS sales_date,
    COALESCE(ssa.store_sales_total, 0) AS store_sales_total,
    COALESCE(ssa.store_net_profit, 0) AS store_net_profit,
    COALESCE(wsa.web_sales_total, 0) AS web_sales_total,
    COALESCE(wsa.web_net_profit, 0) AS web_net_profit,
    COALESCE(cra.total_return_loss, 0) AS total_return_loss,
    COALESCE(ssa.store_transactions, 0) AS store_transactions,
    COALESCE(wsa.web_transactions, 0) AS web_transactions,
    d_closure.d_date AS store_closed_date,
    ROW_NUMBER() OVER (ORDER BY COALESCE(ssa.store_sales_total, 0) DESC) AS sales_rank
FROM store s
LEFT JOIN store_sales_agg ssa
    ON ssa.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_sales
    ON ssa.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN web_sales_agg wsa
    ON wsa.ws_sold_date_sk = d_sales.d_date_sk
LEFT JOIN catalog_returns_agg cra
    ON cra.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
WHERE d_sales.d_date IS NOT NULL
ORDER BY store_sales_total DESC
LIMIT 100
