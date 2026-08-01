WITH sales_customers AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND c.c_birth_year BETWEEN 1960 AND 1980
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd
          WHERE c.c_current_cdemo_sk = cd.cd_demo_sk
            AND cd.cd_gender = 'M'
      )
),
web_return_customers AS (
    SELECT DISTINCT
        cr.c_customer_sk,
        cr.c_customer_id,
        cr.c_birth_year
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer cr ON wr.wr_refunded_customer_sk = cr.c_customer_sk
    WHERE d.d_year = 2001
),
eligible_customers AS (
    SELECT * FROM sales_customers
    INTERSECT
    SELECT * FROM web_return_customers
),
customers_no_store_returns AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_birth_year
    FROM customer c
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
    )
),
sales_with_ticket AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ARRAY[ss.ss_ticket_number, ss.ss_quantity] AS ticket_info
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
)
SELECT DISTINCT
    ec.c_customer_id,
    ec.c_birth_year,
    (
        SELECT SUM(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = ec.c_customer_sk
    ) AS total_net_profit,
    t.val AS ticket_component
FROM eligible_customers ec
JOIN customers_no_store_returns nsr ON ec.c_customer_sk = nsr.c_customer_sk
JOIN sales_with_ticket swt ON ec.c_customer_sk = swt.ss_customer_sk
CROSS JOIN UNNEST(swt.ticket_info) AS t(val)
WHERE ec.c_customer_sk IN (
    SELECT sr2.sr_customer_sk
    FROM store_returns sr2
    WHERE sr2.sr_reason_sk = (
        SELECT r.r_reason_sk
        FROM reason r
        WHERE r.r_reason_desc = 'Customer Not Found'
        LIMIT 1
    )
)
LIMIT 100
