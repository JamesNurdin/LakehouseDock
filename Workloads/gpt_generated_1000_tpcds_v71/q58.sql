WITH
    returns_cte AS (
        SELECT
            c.c_customer_id AS customer_id,
            SUM(sr.sr_return_amt) AS total_amount
        FROM
            store_returns sr
            JOIN item i ON sr.sr_item_sk = i.i_item_sk
            JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
            JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE
            i.i_rec_start_date >= DATE '2000-01-01'
            AND cd.cd_gender = 'F'
            AND cd.cd_education_status = 'Advanced Degree'
        GROUP BY
            c.c_customer_id
    ),
    websales_cte AS (
        SELECT
            c.c_customer_id AS customer_id,
            SUM(ws.ws_ext_sales_price) AS total_amount
        FROM
            web_sales ws
            JOIN item i ON ws.ws_item_sk = i.i_item_sk
            JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
            JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
            JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE
            ws.ws_list_price > 50
            AND w.w_state = 'CA'
            AND cd.cd_gender = 'M'
        GROUP BY
            c.c_customer_id
    )
SELECT DISTINCT
    customer_id,
    'Return' AS activity_type,
    total_amount
FROM
    returns_cte
UNION
SELECT DISTINCT
    customer_id,
    'WebSale' AS activity_type,
    total_amount
FROM
    websales_cte
ORDER BY
    total_amount DESC
LIMIT 100
