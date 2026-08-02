WITH sales_cte AS (
    SELECT
        w.w_warehouse_name AS w_warehouse_name,
        ca.ca_city AS ca_city,
        cs.cs_ext_sales_price AS amount,
        ARRAY[cs.cs_order_number] AS order_ids
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_ext_wholesale_cost > 2000
      AND ca.ca_gmt_offset = -6.00
),
returns_cte AS (
    SELECT
        w.w_warehouse_name AS w_warehouse_name,
        ca.ca_city AS ca_city,
        cr.cr_net_loss AS amount,
        ARRAY[cr.cr_order_number] AS order_ids
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_net_loss > 100
      AND cr.cr_reason_sk IN (4, 41)
      AND ca.ca_gmt_offset = -8.00
),
combined AS (
    SELECT w_warehouse_name, ca_city, amount, order_ids FROM sales_cte
    UNION ALL
    SELECT w_warehouse_name, ca_city, amount, order_ids FROM returns_cte
)
SELECT
    combined.w_warehouse_name,
    combined.ca_city,
    combined.amount,
    order_id
FROM combined
CROSS JOIN UNNEST(combined.order_ids) AS t(order_id)
ORDER BY combined.amount DESC
LIMIT 100
