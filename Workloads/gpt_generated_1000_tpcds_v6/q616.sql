WITH joined AS (
    SELECT
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        t.t_hour,
        t.t_minute,
        t.t_meal_time,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cs.cs_ext_sales_price,
        ss.ss_ext_sales_price
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
        AND cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t.t_time_sk
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    t.t_hour,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(cr.cr_return_amount) DESC) AS rn_return_rank
FROM joined cr
JOIN catalog_sales cs ON 1=1
JOIN store_sales ss ON 1=1
JOIN warehouse w ON 1=1
JOIN time_dim t ON 1=1
WHERE
    cr.cr_return_amount > 100
    AND cs.cs_ext_sales_price > 0
    AND ss.ss_ext_sales_price > 0
    AND t.t_hour BETWEEN 8 AND 20
    AND t.t_minute IN (0, 15, 30, 45)
    AND w.w_state = 'CA'
    AND w.w_city <> 'UNKNOWN'
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    t.t_hour
HAVING
    SUM(cr.cr_return_amount) > 500
ORDER BY total_return_amount DESC
LIMIT 100
