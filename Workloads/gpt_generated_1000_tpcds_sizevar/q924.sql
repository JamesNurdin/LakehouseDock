WITH sub1 AS (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_ext_list_price > 5000
      AND ws.ws_net_paid_inc_ship < 5000
      AND i.i_wholesale_cost BETWEEN 1 AND 100
      AND i.i_manager_id IN (6, 13, 23)
      AND i.i_class = 'accessories'
),
sub2 AS (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_coupon_amt > 100
      AND ws.ws_quantity >= 2
      AND i.i_category = 'shirts'
      AND i.i_color = 'red'
      AND ws.ws_ext_discount_amt < 200
)
SELECT
    ws_order_number,
    i_product_name,
    ws_quantity,
    ws_ext_sales_price,
    coupon_category,
    category_sales_rank,
    order_total
FROM (
    SELECT
        ws.ws_order_number,
        i.i_product_name,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        CASE WHEN ws.ws_coupon_amt > 200 THEN 'HighCoupon' ELSE 'LowCoupon' END AS coupon_category,
        RANK() OVER (PARTITION BY i.i_category ORDER BY ws.ws_ext_sales_price DESC) AS category_sales_rank,
        SUM(ws.ws_ext_sales_price) OVER (PARTITION BY ws.ws_order_number) AS order_total
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_item_sk IN (
        SELECT ws_item_sk FROM sub1 INTERSECT SELECT ws_item_sk FROM sub2
    )
      AND ws.ws_ext_list_price > 3000
      AND ws.ws_net_paid_inc_ship_tax > 4000
      AND i.i_manager_id = 13
      AND i.i_class = 'shirts'
) t1
UNION
SELECT
    ws_order_number,
    i_product_name,
    ws_quantity,
    ws_ext_sales_price,
    coupon_category,
    category_sales_rank,
    order_total
FROM (
    SELECT
        ws.ws_order_number,
        i.i_product_name,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_coupon_amt,
        i.i_category,
        CASE WHEN ws.ws_coupon_amt > 200 THEN 'HighCoupon' ELSE 'LowCoupon' END AS coupon_category,
        DENSE_RANK() OVER (PARTITION BY i.i_category ORDER BY ws.ws_ext_sales_price DESC) AS category_sales_rank,
        SUM(ws.ws_ext_sales_price) OVER (PARTITION BY ws.ws_order_number) AS order_total
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_item_sk IN (
        SELECT ws_item_sk FROM sub1 INTERSECT SELECT ws_item_sk FROM sub2
    )
      AND ws.ws_ext_list_price > 3000
      AND ws.ws_net_paid_inc_ship_tax > 4000
      AND i.i_manager_id = 13
      AND i.i_class = 'shirts'
    GROUP BY
        ws.ws_order_number,
        i.i_product_name,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_coupon_amt,
        i.i_category
    HAVING SUM(ws.ws_ext_sales_price) > 10000
) t2
ORDER BY order_total DESC
OFFSET 0
LIMIT 100
