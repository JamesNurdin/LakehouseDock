WITH base AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_size,
        ca.ca_state,
        ca.ca_zip,
        hd.hd_dep_count,
        ws.ws_wholesale_cost,
        td.t_meal_time,
        td.t_hour,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        ws.ws_order_number
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_category_id IN (1, 3, 5)
      AND i.i_size IN ('medium', 'small')
      AND ca.ca_state = 'CA'
      AND ca.ca_zip LIKE '9%'
      AND hd.hd_dep_count >= 2
      AND ws.ws_wholesale_cost > 30
      AND td.t_meal_time = 'dinner'
),
agg_sales AS (
    SELECT
        category_id,
        t_meal_time AS meal_time,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_quantity) AS avg_quantity,
        COUNT(DISTINCT ws_order_number) AS order_cnt
    FROM base
    GROUP BY category_id, t_meal_time
)
SELECT
    a.category_id,
    a.meal_time,
    a.total_sales,
    a.avg_quantity,
    a.order_cnt
FROM agg_sales a
WHERE a.total_sales > (SELECT AVG(total_sales) FROM agg_sales)
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
        JOIN time_dim td2 ON ws2.ws_sold_time_sk = td2.t_time_sk
        WHERE i2.i_category_id = a.category_id
          AND td2.t_meal_time = a.meal_time
          AND ws2.ws_ext_discount_amt > 0
    )
ORDER BY a.total_sales DESC
OFFSET 0
LIMIT 100
