WITH
    store_sales_filtered AS (
        SELECT
            ss.ss_customer_sk AS cust_sk,
            i.i_category AS category,
            ss.ss_net_paid AS net_paid
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND i.i_units = 'Dozen'
    ),
    web_sales_filtered AS (
        SELECT
            ws.ws_bill_customer_sk AS cust_sk,
            i.i_category AS category,
            ws.ws_net_paid AS net_paid
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND i.i_units = 'Dozen'
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY cust_sk) AS row_num,
    cust_sk,
    category,
    net_paid
FROM (
    SELECT cust_sk, category, net_paid FROM store_sales_filtered
    INTERSECT
    SELECT cust_sk, category, net_paid FROM web_sales_filtered
) intersected
ORDER BY row_num
LIMIT 100
