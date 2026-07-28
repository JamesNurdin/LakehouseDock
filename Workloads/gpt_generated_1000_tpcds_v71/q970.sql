WITH inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_warehouse_sk, inv_date_sk
),
sales_union AS (
    SELECT
        s.s_state AS s_state,
        sm.sm_type AS sm_type,
        w.w_city AS w_city,
        d_sold.d_year AS d_year,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        MAX(cs.cs_ext_sales_price) AS max_sale,
        AVG(cs.cs_quantity) AS avg_quantity,
        ia.total_on_hand AS total_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory_agg ia ON ia.inv_warehouse_sk = w.w_warehouse_sk
                       AND ia.inv_date_sk = d_ship.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
    GROUP BY s.s_state, sm.sm_type, w.w_city, d_sold.d_year, ia.total_on_hand

    UNION ALL

    SELECT
        s.s_state AS s_state,
        sm.sm_type AS sm_type,
        w.w_city AS w_city,
        d_sold.d_year AS d_year,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        MAX(cs.cs_ext_sales_price) AS max_sale,
        AVG(cs.cs_quantity) AS avg_quantity,
        ia.total_on_hand AS total_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory_agg ia ON ia.inv_warehouse_sk = w.w_warehouse_sk
                       AND ia.inv_date_sk = d_ship.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2002
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
    GROUP BY s.s_state, sm.sm_type, w.w_city, d_sold.d_year, ia.total_on_hand
)
SELECT
    s_state,
    sm_type,
    w_city,
    d_year,
    SUM(orders) AS total_orders,
    SUM(total_sales) AS total_sales,
    SUM(total_profit) AS total_profit,
    MAX(max_sale) AS max_sale,
    AVG(avg_quantity) AS avg_quantity,
    MAX(total_on_hand) AS total_on_hand
FROM sales_union
GROUP BY s_state, sm_type, w_city, d_year
ORDER BY total_sales DESC
LIMIT 100
