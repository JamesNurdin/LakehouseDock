WITH catalog_data AS (
    SELECT
        c.c_customer_id AS customer_id,
        cs.cs_sold_date_sk AS sale_date_sk,
        cs.cs_net_paid AS net_paid,
        cd.cd_gender AS gender,
        (
            SELECT AVG(cs2.cs_net_paid)
            FROM catalog_sales cs2
            WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
        ) AS avg_customer_net_paid
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND cs.cs_net_paid > 500
),
store_data AS (
    SELECT
        c.c_customer_id AS customer_id,
        ss.ss_sold_date_sk AS sale_date_sk,
        ss.ss_net_paid AS net_paid,
        cd.cd_gender AS gender,
        (
            SELECT AVG(ss2.ss_net_paid)
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = c.c_customer_sk
        ) AS avg_customer_net_paid
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND ss.ss_net_paid > 500
)
SELECT
    customer_id,
    sale_date_sk,
    net_paid,
    gender,
    avg_customer_net_paid
FROM catalog_data
UNION ALL
SELECT
    customer_id,
    sale_date_sk,
    net_paid,
    gender,
    avg_customer_net_paid
FROM store_data
ORDER BY net_paid DESC
LIMIT 100
