WITH
    order_keys_1 AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
        WHERE d1.d_year = 2001
          AND cs.cs_ext_sales_price > 800
    ),
    order_keys_2 AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE cc.cc_state = 'CA'
          AND cs.cs_quantity > 5
    ),
    intersect_keys AS (
        SELECT cs_order_number
        FROM order_keys_1
        INTERSECT
        SELECT cs_order_number
        FROM order_keys_2
    )
SELECT
    cs.cs_order_number,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    cc.cc_name,
    w.w_warehouse_name,
    i.inv_quantity_on_hand,
    wp.wp_url,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    SUM(cs.cs_net_profit) OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY d_sold.d_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_profit,
    RANK() OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY cs.cs_net_profit DESC
    ) AS profit_rank
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
               AND i.inv_date_sk = d_sold.d_date_sk
JOIN web_page wp ON wp.wp_access_date_sk = d_ship.d_date_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
WHERE cs.cs_quantity > 2
  AND cs.cs_ext_sales_price > 1000
  AND d_sold.d_year = 2002
  AND w.w_state = 'CA'
  AND cs.cs_order_number IN (SELECT cs_order_number FROM intersect_keys)
ORDER BY profit_rank, cs.cs_order_number
LIMIT 100
