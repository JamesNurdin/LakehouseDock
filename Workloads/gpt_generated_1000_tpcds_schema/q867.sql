WITH full_sales_time AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_customer_sk,
        t.t_meal_time,
        (
            SELECT COUNT(*)
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = ss.ss_customer_sk
        ) AS cust_sales_cnt
    FROM store_sales ss TABLESAMPLE BERNOULLI (10)
    FULL OUTER JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
),

web_sales_union AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS qty,
        ws.ws_net_paid AS net_paid,
        wp.wp_type AS page_type,
        (
            SELECT SUM(ws2.ws_ext_sales_price)
            FROM web_sales ws2
            WHERE ws2.ws_bill_customer_sk = ws.ws_bill_customer_sk
        ) AS bill_customer_total
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_net_paid > 1000

    UNION

    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        -wr.wr_return_quantity,
        -wr.wr_return_amt,
        CAST(NULL AS varchar) AS page_type,
        (
            SELECT SUM(wr2.wr_return_amt)
            FROM web_returns wr2
            WHERE wr2.wr_refunded_customer_sk = wr.wr_refunded_customer_sk
        ) AS refunded_customer_total
    FROM web_returns wr
    WHERE wr.wr_return_amt > 500
),

cust_intersect AS (
    SELECT cr.cr_refunded_customer_sk AS cust_sk
    FROM catalog_returns cr
    INTERSECT
    SELECT wr.wr_refunded_customer_sk
    FROM web_returns wr
)

SELECT
    f.date_sk,
    f.item_sk,
    f.quantity,
    f.net_paid,
    f.t_meal_time,
    u.page_type,
    ci.cust_sk
FROM full_sales_time f
LEFT JOIN web_sales_union u
    ON f.item_sk = u.item_sk
LEFT JOIN cust_intersect ci
    ON f.ss_customer_sk = ci.cust_sk
ORDER BY f.net_paid DESC
LIMIT 100
