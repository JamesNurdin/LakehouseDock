WITH sales_sports AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE i.i_class = 'sports-apparel'
      AND c.c_birth_day > 15
    GROUP BY i.i_item_id, i.i_category
),
sales_manufact AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE i.i_manufact_id = 260
      AND c.c_first_sales_date_sk >= 2449660
    GROUP BY i.i_item_id, i.i_category
)
SELECT i_item_id,
       i_category,
       total_net_paid,
       distinct_customers
FROM sales_sports
UNION ALL
SELECT i_item_id,
       i_category,
       total_net_paid,
       distinct_customers
FROM sales_manufact
