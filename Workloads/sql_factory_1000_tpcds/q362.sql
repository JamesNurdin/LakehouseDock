WITH cust_spending AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ss.ss_ext_sales_price) AS total_spent,
        SUM(ss.ss_quantity) AS total_items,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        MAX(ss.ss_sold_date_sk) AS last_purchase_date_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
),
segmented_customers AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        cd_gender,
        total_spent,
        total_items,
        CASE
            WHEN total_spent >= 10000 THEN 'Platinum'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 2000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_segment,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_spent DESC) AS gender_spend_rank
    FROM cust_spending
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    cd_gender,
    total_spent,
    total_items,
    customer_segment,
    gender_spend_rank
FROM segmented_customers
WHERE gender_spend_rank <= 5
ORDER BY cd_gender, total_spent DESC
