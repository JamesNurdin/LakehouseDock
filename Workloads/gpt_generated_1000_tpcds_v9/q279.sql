WITH filtered_sales AS (
    SELECT
        cs_order_number,
        cs_item_sk,
        cs_warehouse_sk,
        cs_net_paid_inc_ship_tax,
        cs_wholesale_cost,
        cs_ext_ship_cost
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship_tax > 5000
      AND cs_wholesale_cost < 30
      AND cs_ext_ship_cost < 500
),
filtered_returns AS (
    SELECT
        cr_order_number,
        cr_item_sk,
        cr_warehouse_sk,
        cr_return_amount,
        cr_refunded_cash,
        cr_reversed_charge,
        cr_net_loss
    FROM catalog_returns
    WHERE cr_refunded_cash > 500
      AND cr_reversed_charge < 100
),
eligible_orders AS (
    SELECT cs_order_number FROM filtered_sales
    EXCEPT
    SELECT cr_order_number FROM filtered_returns
),
joined_data AS (
    SELECT
        ws.w_city,
        ws.w_county,
        f_sales.cs_order_number,
        f_sales.cs_net_paid_inc_ship_tax,
        f_sales.cs_wholesale_cost,
        f_sales.cs_ext_ship_cost,
        f_returns.cr_return_amount,
        f_returns.cr_refunded_cash,
        f_returns.cr_net_loss
    FROM filtered_sales f_sales
    LEFT JOIN filtered_returns f_returns
        ON f_sales.cs_order_number = f_returns.cr_order_number
        AND f_sales.cs_item_sk = f_returns.cr_item_sk
    JOIN warehouse ws
        ON f_sales.cs_warehouse_sk = ws.w_warehouse_sk
    WHERE f_sales.cs_order_number IN (SELECT cs_order_number FROM eligible_orders)
      AND ws.w_city = 'Pleasant Hill'
      AND ws.w_county = 'Marshall County'
)
SELECT
    w_city,
    w_county,
    COUNT(DISTINCT cs_order_number) AS total_orders,
    SUM(cs_net_paid_inc_ship_tax) AS total_sales_amount,
    AVG(cs_wholesale_cost) AS avg_wholesale_cost,
    SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(cr_refunded_cash, 0)) AS total_refunded_cash,
    SUM(COALESCE(cr_net_loss, 0)) AS total_net_loss
FROM joined_data
GROUP BY w_city, w_county
ORDER BY total_sales_amount DESC
LIMIT 100
