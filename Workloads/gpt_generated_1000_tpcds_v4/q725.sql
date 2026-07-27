WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_salutation,
        c.c_birth_month,
        COUNT(ss.ss_ticket_number) AS cnt_sales,
        SUM(ss.ss_net_paid_inc_tax) AS total_paid_inc_tax,
        AVG(ss.ss_net_profit) AS avg_profit,
        MIN(ss.ss_net_paid_inc_tax) AS min_paid,
        MAX(ss.ss_net_paid_inc_tax) AS max_paid
    FROM
        tpcds.customer c
    JOIN
        tpcds.store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_month = 5
        AND c.c_salutation = 'Mr.'
        AND ss.ss_net_paid_inc_tax > 100.00
        AND ss.ss_quantity >= 2
        AND ss.ss_ext_discount_amt < 50.00
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_salutation,
        c.c_birth_month
)
SELECT
    sa.c_customer_id,
    sa.c_salutation,
    sa.c_birth_month,
    sa.cnt_sales,
    sa.total_paid_inc_tax,
    sa.avg_profit,
    sa.min_paid,
    sa.max_paid
FROM
    sales_agg sa
WHERE
    EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr
        WHERE wr.wr_returning_customer_sk = sa.c_customer_sk
          AND wr.wr_return_quantity > 0
          AND wr.wr_return_amt > 20.00
          AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
          AND wr.wr_reason_sk IN (1010209, 1360384)
    )
ORDER BY
    sa.total_paid_inc_tax DESC,
    sa.cnt_sales DESC
LIMIT 100
