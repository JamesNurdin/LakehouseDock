WITH sales_union AS (
    SELECT
        ss.ss_ticket_number AS ticket_number,
        ss.ss_store_sk AS store_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_ext_sales_price AS ext_sales_price,
        'store' AS channel,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_sold_time_sk AS sold_time_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    UNION ALL
    SELECT
        ws.ws_order_number AS ticket_number,
        NULL AS store_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_ext_sales_price AS ext_sales_price,
        'web' AS channel,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_sold_time_sk AS sold_time_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
),
returns_union AS (
    SELECT
        sr.sr_ticket_number AS ticket_number,
        sr.sr_return_amt AS return_amount,
        sr.sr_store_sk AS store_sk,
        sr.sr_customer_sk AS customer_sk
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_order_number AS ticket_number,
        wr.wr_return_amt AS return_amount,
        NULL AS store_sk,
        wr.wr_refunded_customer_sk AS customer_sk
    FROM web_returns wr
),
sales_without_returns AS (
    SELECT
        su.ticket_number,
        su.store_sk,
        su.customer_sk,
        su.net_paid,
        su.ext_sales_price,
        su.channel,
        su.sold_date_sk,
        su.sold_time_sk
    FROM sales_union su
    EXCEPT
    SELECT
        ru.ticket_number,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    FROM returns_union ru
)
SELECT
    swr.channel,
    COUNT(DISTINCT swr.ticket_number) AS distinct_ticket_cnt,
    SUM(DISTINCT swr.ext_sales_price) AS distinct_sales_sum,
    CASE WHEN COUNT(DISTINCT swr.ticket_number) > 100 THEN 'HighVolume' ELSE 'LowVolume' END AS volume_category,
    (SELECT MAX(ss_net_paid) FROM store_sales) AS max_store_net_paid,
    agg.avg_store_discount
FROM sales_without_returns swr
LEFT JOIN LATERAL (
    SELECT AVG(ss_ext_discount_amt) AS avg_store_discount
    FROM store_sales ss
    WHERE ss.ss_store_sk = swr.store_sk
) agg ON true
WHERE EXISTS (
    SELECT 1
    FROM customer c
    WHERE c.c_customer_sk = swr.customer_sk
      AND c.c_preferred_cust_flag = 'Y'
)
GROUP BY swr.channel, agg.avg_store_discount
ORDER BY distinct_ticket_cnt DESC
LIMIT 100
