WITH wr_agg AS (
    SELECT
        wr_order_number,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns
    GROUP BY wr_order_number
),
max_ship_cost AS (
    SELECT MAX(cs_ext_ship_cost) AS max_ship_cost
    FROM catalog_sales
)
,
union_src AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_ext_sales_price AS sales_amount,
        COALESCE(wa.total_return_amt, 0) AS total_return_amt,
        sm.sm_type AS ship_type,
        CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_mode_category,
        ROW_NUMBER() OVER (PARTITION BY sm.sm_type ORDER BY cs.cs_ext_sales_price DESC) AS rn,
        (SELECT max_ship_cost FROM max_ship_cost) AS max_ship_cost_global,
        (SELECT SUM(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
         WHERE cs2.cs_ship_mode_sk = cs.cs_ship_mode_sk) AS ship_mode_total_sales
    FROM catalog_sales cs
    JOIN date_dim d_sold          ON cs.cs_sold_date_sk   = d_sold.d_date_sk
    JOIN time_dim t_sold          ON cs.cs_sold_time_sk   = t_sold.t_time_sk
    JOIN ship_mode sm            ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w             ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN customer c_bill         ON cs.cs_bill_customer_sk   = c_bill.c_customer_sk
    JOIN customer c_ship         ON cs.cs_ship_customer_sk   = c_ship.c_customer_sk
    JOIN date_dim d_ship          ON cs.cs_ship_date_sk   = d_ship.d_date_sk
    LEFT JOIN wr_agg wa          ON cs.cs_order_number   = wa.wr_order_number
    WHERE cs.cs_ext_sales_price > (
        SELECT AVG(cs_ext_sales_price) FROM catalog_sales
    )
    UNION DISTINCT
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_ext_sales_price AS sales_amount,
        (
            SELECT COALESCE(SUM(wr.wr_return_amt), 0)
            FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
        ) AS total_return_amt,
        sm2.sm_type AS ship_type,
        CASE WHEN sm2.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_mode_category,
        ROW_NUMBER() OVER (PARTITION BY sm2.sm_type ORDER BY ws.ws_ext_sales_price DESC) AS rn,
        (SELECT max_ship_cost FROM max_ship_cost) AS max_ship_cost_global,
        (SELECT SUM(ws2.ws_ext_sales_price)
         FROM web_sales ws2
         WHERE ws2.ws_ship_mode_sk = ws.ws_ship_mode_sk) AS ship_mode_total_sales
    FROM web_sales ws
    JOIN date_dim d_ws_sold       ON ws.ws_sold_date_sk   = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold       ON ws.ws_sold_time_sk   = t_ws_sold.t_time_sk
    JOIN ship_mode sm2            ON ws.ws_ship_mode_sk   = sm2.sm_ship_mode_sk
    JOIN warehouse w2            ON ws.ws_warehouse_sk   = w2.w_warehouse_sk
    JOIN customer c_bill2        ON ws.ws_bill_customer_sk   = c_bill2.c_customer_sk
    JOIN web_page wp             ON ws.ws_web_page_sk   = wp.wp_web_page_sk
    WHERE ws.ws_ext_sales_price > (
        SELECT AVG(ws_ext_sales_price) FROM web_sales
    )
)
SELECT
    ship_type,
    SUM(sales_amount)               AS total_sales,
    SUM(total_return_amt)           AS total_returns,
    COUNT(DISTINCT order_number)    AS num_orders,
    MAX(max_ship_cost_global)       AS max_ship_cost_global,
    AVG(ship_mode_total_sales)      AS avg_ship_mode_total_sales,
    MAX(rn)                         AS max_row_number
FROM union_src
GROUP BY ship_type
ORDER BY total_sales DESC
LIMIT 100
