WITH union_data AS (
    -- First branch: billing customer perspective
    SELECT
        w.w_warehouse_name AS warehouse_name,
        r.r_reason_desc AS reason_desc,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS profit,
        ws.ws_order_number AS order_num,
        (
            SELECT AVG(ws2.ws_ext_discount_amt)
            FROM web_sales ws2
            WHERE ws2.ws_warehouse_sk = ws.ws_warehouse_sk
        ) AS avg_warehouse_discount,
        CASE WHEN ws.ws_ext_sales_price > 10000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM web_sales ws
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE c_bill.c_birth_year = 1955
      AND w.w_state = 'CA'
      AND r.r_reason_id = 'R001'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ws.ws_ext_list_price > 5000
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_order_number = ws.ws_order_number
            AND wr2.wr_return_quantity > 0
      )
    UNION
    -- Second branch: shipping customer perspective
    SELECT
        w.w_warehouse_name AS warehouse_name,
        r.r_reason_desc AS reason_desc,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS profit,
        ws.ws_order_number AS order_num,
        (
            SELECT AVG(ws2.ws_ext_discount_amt)
            FROM web_sales ws2
            WHERE ws2.ws_warehouse_sk = ws.ws_warehouse_sk
        ) AS avg_warehouse_discount,
        CASE WHEN ws.ws_ext_sales_price > 10000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM web_sales ws
    JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE c_ship.c_preferred_cust_flag = 'Y'
      AND w.w_city = 'Los Angeles'
      AND r.r_reason_desc LIKE '%Damaged%'
      AND ws.ws_sold_date_sk BETWEEN 2450050 AND 2450150
      AND ws.ws_ext_list_price > 8000
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_order_number = ws.ws_order_number
            AND wr2.wr_return_quantity > 0
      )
)
SELECT
    warehouse_name,
    reason_desc,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT order_num) AS distinct_orders,
    AVG(profit) AS avg_profit,
    AVG(avg_warehouse_discount) AS avg_discount_across_warehouse,
    CASE WHEN SUM(sales_amount) > 200000 THEN 'Very High' ELSE 'Moderate' END AS overall_sales_category
FROM union_data
GROUP BY warehouse_name, reason_desc
HAVING SUM(sales_amount) > 50000
ORDER BY total_sales DESC
LIMIT 100
