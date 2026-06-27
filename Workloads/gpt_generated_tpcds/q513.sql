WITH sales_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        SUM(cs.cs_net_paid) AS total_sales_net_paid,
        SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
        SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
        SUM(cs.cs_quantity) AS total_sold_quantity,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_sales_orders
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_state
),
returns_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_state
)
SELECT
    s.w_warehouse_id,
    s.w_warehouse_name,
    s.w_state,
    s.total_sales_net_paid,
    s.total_ext_sales_price,
    s.total_discount_amount,
    s.total_sales_profit,
    r.total_return_loss,
    r.total_return_quantity,
    r.avg_return_amount,
    s.distinct_sales_orders,
    r.distinct_return_orders,
    s.total_discount_amount * 1.0 / NULLIF(s.distinct_sales_orders, 0) AS avg_discount_per_order,
    r.total_return_quantity * 1.0 / NULLIF(s.total_sold_quantity, 0) AS return_quantity_rate,
    (s.total_sales_profit - r.total_return_loss) AS net_gain
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.w_warehouse_id = r.w_warehouse_id
    AND s.w_warehouse_name = r.w_warehouse_name
    AND s.w_state = r.w_state
ORDER BY net_gain DESC
LIMIT 5
