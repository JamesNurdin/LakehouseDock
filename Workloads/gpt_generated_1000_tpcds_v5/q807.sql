WITH warehouse_info AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        w_city
    FROM warehouse
)
,
returns_agg AS (
    SELECT
        'return' AS source,
        wi.w_warehouse_name,
        wi.w_city,
        td.t_hour,
        SUM(cr.cr_return_amount) AS metric
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN warehouse_info wi
        ON cr.cr_warehouse_sk = wi.w_warehouse_sk
    WHERE cr.cr_return_amount > 100
      AND td.t_hour BETWEEN 8 AND 12
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          WHERE cs.cs_order_number = cr.cr_order_number
            AND cs.cs_item_sk = cr.cr_item_sk
      )
    GROUP BY wi.w_warehouse_name, wi.w_city, td.t_hour
)
,
sales_agg AS (
    SELECT
        'sale' AS source,
        wi.w_warehouse_name,
        wi.w_city,
        td.t_hour,
        SUM(cs.cs_net_profit) AS metric
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN warehouse_info wi
        ON cs.cs_warehouse_sk = wi.w_warehouse_sk
    WHERE cs.cs_net_profit > 50
      AND td.t_hour BETWEEN 8 AND 12
    GROUP BY wi.w_warehouse_name, wi.w_city, td.t_hour
)
SELECT source,
       w_warehouse_name,
       w_city,
       t_hour,
       metric
FROM returns_agg
UNION ALL
SELECT source,
       w_warehouse_name,
       w_city,
       t_hour,
       metric
FROM sales_agg
ORDER BY metric DESC
LIMIT 100
