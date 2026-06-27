WITH
catalog_sales_agg AS (
    SELECT
        cs_warehouse_sk,
        sum(cs_net_paid) AS total_sales_net_paid,
        sum(cs_net_profit) AS total_sales_net_profit,
        sum(cs_quantity) AS total_sales_quantity,
        count(DISTINCT cs_order_number) AS distinct_sales_orders
    FROM catalog_sales
    GROUP BY cs_warehouse_sk
),
catalog_returns_agg AS (
    SELECT
        cr_warehouse_sk,
        sum(cr_refunded_cash) AS total_refunded_cash,
        sum(cr_net_loss) AS total_net_loss,
        sum(cr_return_quantity) AS total_return_quantity,
        count(DISTINCT cr_order_number) AS distinct_return_orders
    FROM catalog_returns
    GROUP BY cr_warehouse_sk
),
web_sales_agg AS (
    SELECT
        ws_warehouse_sk,
        sum(ws_net_paid) AS total_web_net_paid,
        sum(ws_net_profit) AS total_web_net_profit,
        sum(ws_quantity) AS total_web_quantity,
        count(DISTINCT ws_order_number) AS distinct_web_orders
    FROM web_sales
    GROUP BY ws_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    coalesce(cs.total_sales_net_paid, 0) AS total_catalog_sales_net_paid,
    coalesce(cs.total_sales_net_profit, 0) AS total_catalog_sales_net_profit,
    coalesce(cr.total_refunded_cash, 0) AS total_refunded_cash,
    coalesce(cr.total_net_loss, 0) AS total_catalog_return_net_loss,
    coalesce(ws.total_web_net_paid, 0) AS total_web_sales_net_paid,
    coalesce(ws.total_web_net_profit, 0) AS total_web_sales_net_profit,
    -- overall net profit combining catalog sales, returns loss, and web sales
    coalesce(cs.total_sales_net_profit, 0) - coalesce(cr.total_net_loss, 0) + coalesce(ws.total_web_net_profit, 0) AS overall_net_profit,
    -- ratios
    CAST(cr.total_return_quantity AS double) / NULLIF(cs.total_sales_quantity, 0) AS return_quantity_ratio,
    CAST(cr.total_net_loss AS double) / NULLIF(cs.total_sales_net_profit, 0) AS return_loss_to_profit_ratio,
    CAST(cr.total_refunded_cash AS double) / NULLIF(cs.total_sales_net_paid, 0) AS refunded_cash_to_sales_ratio,
    coalesce(cs.distinct_sales_orders, 0) AS catalog_distinct_orders,
    coalesce(cr.distinct_return_orders, 0) AS returns_distinct_orders,
    coalesce(ws.distinct_web_orders, 0) AS web_distinct_orders
FROM warehouse w
LEFT JOIN catalog_sales_agg cs ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns_agg cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_sales_agg ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
ORDER BY overall_net_profit DESC
LIMIT 20
