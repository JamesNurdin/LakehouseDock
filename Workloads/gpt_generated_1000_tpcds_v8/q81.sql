WITH base AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_sales_price,
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_wholesale_cost,
        c.c_customer_id,
        c.c_birth_country,
        c.c_birth_year,
        cd.cd_dep_employed_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_category_id = 3
      AND i.i_wholesale_cost > 5.00
      AND c.c_birth_country = 'KOREA'
      AND c.c_birth_year BETWEEN 1970 AND 1985
      AND cd.cd_dep_employed_count >= 2
      AND i.i_item_id NOT IN (
          SELECT i2.i_item_id
          FROM item i2
          WHERE i2.i_wholesale_cost < 1.00
      )
)
SELECT
    base.c_customer_id,
    base.c_birth_country,
    base.i_category,
    base.i_brand,
    SUM(base.ws_ext_sales_price) AS total_sales,
    AVG(base.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT base.ws_order_number) AS distinct_orders,
    MIN(base.ws_ship_date_sk) AS first_ship_date_sk,
    MAX(base.ws_ship_date_sk) AS last_ship_date_sk
FROM base
GROUP BY
    base.c_customer_id,
    base.c_birth_country,
    base.i_category,
    base.i_brand
ORDER BY total_sales DESC
LIMIT 100
