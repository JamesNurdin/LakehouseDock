WITH sales_returns AS (
    SELECT
        c.c_customer_id,
        c.c_birth_country,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        SUM(r.sr_refunded_cash) AS total_refunded,
        COUNT(r.sr_ticket_number) AS return_transactions,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'VIP' ELSE 'Regular' END AS customer_segment
    FROM
        tpcds.customer c
    JOIN tpcds.store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.store_returns r
        ON r.sr_ticket_number = ss.ss_ticket_number
        AND r.sr_item_sk = ss.ss_item_sk
    WHERE
        c.c_birth_month = 8
        AND c.c_birth_country = 'MEXICO'
        AND ss.ss_ext_list_price > 1000
        AND ss.ss_net_paid BETWEEN 1000 AND 5000
        AND r.sr_return_quantity >= 20
        AND r.sr_returned_date_sk BETWEEN 2451000 AND 2452000
        AND EXISTS (
            SELECT 1
            FROM tpcds.store_returns r2
            WHERE r2.sr_customer_sk = c.c_customer_sk
              AND r2.sr_return_quantity > 30
        )
    GROUP BY
        c.c_customer_id,
        c.c_birth_country
)
SELECT *
FROM sales_returns
ORDER BY total_sales DESC
LIMIT 100
