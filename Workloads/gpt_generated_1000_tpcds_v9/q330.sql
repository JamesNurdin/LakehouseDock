WITH
sales AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_sold_date_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_ext_tax,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk >= 2451545
      AND cs.cs_sold_date_sk <= 2454015
      AND cs.cs_net_paid_inc_tax > 1000
      AND cs.cs_ext_tax >= 10
      AND cs.cs_ext_tax <= 200
),
cust_demo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM customer c
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_month IN (1, 2, 3, 4)
      AND c.c_preferred_cust_flag = 'Y'
      AND cd.cd_credit_rating IN ('A', 'B')
),
returns AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        sr.sr_returned_date_sk
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_net_loss > 0
      AND sr.sr_return_amt >= 20
      AND sr.sr_returned_date_sk >= 2451545
      AND sr.sr_returned_date_sk <= 2454015
),
sales_cust AS (
    SELECT
        s.cust_sk,
        s.cs_sold_date_sk,
        s.cs_net_paid_inc_tax,
        s.cs_ext_tax,
        s.cs_order_number,
        cd.c_first_name,
        cd.c_last_name,
        cd.c_birth_month,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM sales s
    INNER JOIN cust_demo cd
        ON s.cust_sk = cd.c_customer_sk
),
customer_sales_returns AS (
    SELECT
        sc.cust_sk,
        sc.c_first_name,
        sc.c_last_name,
        sc.c_birth_month,
        sc.cd_gender,
        sc.cs_sold_date_sk,
        sc.cs_net_paid_inc_tax,
        sc.cs_ext_tax,
        r.sr_return_amt,
        r.sr_net_loss,
        r.sr_return_quantity
    FROM sales_cust sc
    LEFT OUTER JOIN returns r
        ON r.sr_customer_sk = sc.cust_sk
)
SELECT
    csr.cust_sk,
    csr.c_first_name,
    csr.c_last_name,
    csr.c_birth_month,
    csr.cd_gender,
    SUM(csr.cs_net_paid_inc_tax) AS total_sales,
    SUM(COALESCE(csr.sr_return_amt, 0)) AS total_returns,
    SUM(COALESCE(csr.sr_net_loss, 0)) AS total_return_loss,
    RANK() OVER (ORDER BY SUM(csr.cs_net_paid_inc_tax) DESC) AS sales_rank,
    CASE
        WHEN SUM(COALESCE(csr.sr_net_loss, 0)) > 1000 THEN 'High Loss'
        ELSE 'Low Loss'
    END AS loss_category
FROM customer_sales_returns csr
GROUP BY
    csr.cust_sk,
    csr.c_first_name,
    csr.c_last_name,
    csr.c_birth_month,
    csr.cd_gender
HAVING SUM(csr.cs_net_paid_inc_tax) > 2000
ORDER BY sales_rank
LIMIT 100
