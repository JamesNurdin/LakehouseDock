WITH
store_sales_data AS (
    SELECT DISTINCT
        c.c_customer_id,
        ss.ss_sold_date_sk AS sold_date_sk,
        i.i_item_id,
        i.i_product_name,
        ss.ss_net_paid AS net_paid,
        SUM(ss.ss_net_paid) OVER (
            PARTITION BY c.c_customer_id
            ORDER BY ss.ss_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_customer_sales
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_paid > 100
      AND i.i_category = 'Sports'
),
web_sales_data AS (
    SELECT DISTINCT
        c.c_customer_id,
        ws.ws_sold_date_sk AS sold_date_sk,
        i.i_item_id,
        i.i_product_name,
        ws.ws_net_paid AS net_paid,
        SUM(ws.ws_net_paid) OVER (
            PARTITION BY c.c_customer_id
            ORDER BY ws.ws_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_customer_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_net_paid > 100
      AND i.i_category = 'Sports'
)
SELECT
    combined.c_customer_id,
    combined.sold_date_sk,
    combined.i_item_id,
    combined.i_product_name,
    combined.net_paid,
    combined.cumulative_customer_sales
FROM (
    SELECT * FROM store_sales_data
    UNION ALL
    SELECT * FROM web_sales_data
) AS combined
WHERE combined.net_paid > (
    SELECT AVG(cs.cs_net_paid_inc_ship)
    FROM catalog_sales cs
    WHERE cs.cs_ship_date_sk = combined.sold_date_sk
)
ORDER BY combined.net_paid DESC
LIMIT 100
