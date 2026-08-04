/* goal: Compare top sales amounts from physical store and web channels for specific days and item classes, deduplicate across channels, and show the most recent year in the data */
WITH
store_part AS (
    SELECT
        d.d_date AS sale_date,
        i.i_item_id AS item_id,
        c.c_customer_id AS customer_id,
        lt.line_total AS total_sales,
        'store' AS sales_channel,
        (SELECT max(d2.d_year) FROM tpcds.date_dim d2) AS max_year
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d       ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i           ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer c       ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT ss.ss_quantity * ss.ss_sales_price AS line_total
    ) AS lt
    WHERE d.d_day_name = 'Saturday'
      AND i.i_class_id = 13
      AND EXISTS (
          SELECT 1
          FROM tpcds.household_demographics hd2
          WHERE hd2.hd_demo_sk = c.c_current_hdemo_sk
            AND hd2.hd_vehicle_count > 2
      )
),
web_part AS (
    SELECT
        d.d_date AS sale_date,
        i.i_item_id AS item_id,
        c.c_customer_id AS customer_id,
        lt.line_total AS total_sales,
        'web' AS sales_channel,
        (SELECT max(d2.d_year) FROM tpcds.date_dim d2) AS max_year
    FROM tpcds.web_sales ws
    TABLESAMPLE BERNOULLI (10)
    JOIN tpcds.date_dim d       ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i           ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer c       ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT ws.ws_quantity * ws.ws_sales_price AS line_total
    ) AS lt
    WHERE d.d_day_name = 'Wednesday'
      AND i.i_class_id = 14
      AND EXISTS (
          SELECT 1
          FROM tpcds.household_demographics hd2
          WHERE hd2.hd_demo_sk = c.c_current_hdemo_sk
            AND hd2.hd_vehicle_count > 2
      )
)
SELECT
    sale_date,
    item_id,
    customer_id,
    total_sales,
    sales_channel,
    max_year
FROM (
    SELECT * FROM store_part
    UNION
    SELECT * FROM web_part
) AS combined
ORDER BY total_sales DESC
LIMIT 100
