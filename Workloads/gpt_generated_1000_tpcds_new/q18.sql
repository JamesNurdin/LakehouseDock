WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_item_sk,
        c_bill.c_birth_country AS bill_birth_country,
        cd_bill.cd_gender AS bill_gender,
        cr.cr_return_amount,
        cr.cr_net_loss,
        wr.wr_return_amt,
        c_refunded.c_customer_id AS refunded_customer_id,
        cd_refunded.cd_gender AS refunded_gender,
        c_returning.c_customer_id AS returning_customer_id,
        cd_returning.cd_gender AS returning_gender
    FROM catalog_sales cs
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    LEFT JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    LEFT JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    LEFT JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    LEFT JOIN web_returns wr2
        ON wr2.wr_returning_customer_sk = c_returning.c_customer_sk
        AND wr2.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM web_returns wr_not
        WHERE wr_not.wr_order_number = cr.cr_order_number
    )
),
sales_filtered1 AS (
    SELECT * FROM sales_base WHERE bill_birth_country = 'SWITZERLAND'
),
sales_filtered2 AS (
    SELECT * FROM sales_base WHERE bill_birth_country = 'PHILIPPINES'
),
unioned AS (
    SELECT * FROM sales_filtered1
    UNION DISTINCT
    SELECT * FROM sales_filtered2
),
agg AS (
    SELECT
        bill_birth_country,
        bill_gender,
        COUNT(DISTINCT cs_order_number) AS orders,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(wr_return_amt, 0)) AS total_web_return_amount
    FROM unioned
    GROUP BY bill_birth_country, bill_gender
)
SELECT
    bill_birth_country,
    bill_gender,
    orders,
    total_net_paid,
    total_return_amount,
    total_web_return_amount,
    ROW_NUMBER() OVER (PARTITION BY bill_birth_country ORDER BY total_net_paid DESC) AS row_num
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
