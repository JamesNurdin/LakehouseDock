WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        w.w_warehouse_name AS w_warehouse_name,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        p.p_channel_demo,
        p.p_start_date_sk,
        p.p_end_date_sk
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
)
SELECT *
FROM (
    SELECT
        w_warehouse_name,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM base_sales
    WHERE p_channel_demo = 'N'
      AND p_start_date_sk >= 2450300
    GROUP BY w_warehouse_name

    UNION ALL

    SELECT
        w_warehouse_name,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM base_sales
    WHERE p_channel_demo <> 'N'
      AND p_end_date_sk <= 2450580
    GROUP BY w_warehouse_name
) AS combined
ORDER BY total_net_profit DESC
LIMIT 20
