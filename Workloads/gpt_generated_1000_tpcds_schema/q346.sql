WITH cs_cust AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_month,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(cs.cs_ext_list_price) AS total_list_price,
        COUNT(*) AS sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY c.c_birth_month ORDER BY SUM(cs.cs_net_paid_inc_tax) DESC) AS rank_by_month
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_list_price > 5000
      AND cs.cs_net_paid_inc_tax >= 100
      AND c.c_birth_month IN (5, 8, 11, 4)
      AND c.c_last_review_date > 2452400
    GROUP BY c.c_customer_sk, c.c_birth_month
),

sr_cust AS (
    SELECT
        c.c_customer_sk,
        SUM(sr.sr_refunded_cash) AS total_refunded,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_refunded_cash > 100
      AND sr.sr_return_quantity >= 1
      AND c.c_birth_month IN (5, 8, 11, 4)
      AND c.c_first_shipto_date_sk < 2450000
    GROUP BY c.c_customer_sk
),

combined AS (
    SELECT
        COALESCE(cs.c_customer_sk, sr.c_customer_sk) AS customer_sk,
        cs.c_birth_month,
        cs.total_net_paid,
        cs.total_list_price,
        cs.sales_cnt,
        cs.rank_by_month,
        sr.total_refunded,
        sr.total_net_loss,
        sr.return_cnt
    FROM cs_cust cs
    FULL OUTER JOIN sr_cust sr
        ON cs.c_customer_sk = sr.c_customer_sk
)

SELECT
    customer_sk,
    c_birth_month,
    total_net_paid,
    total_refunded,
    total_list_price,
    sales_cnt,
    return_cnt,
    (total_net_paid - total_refunded) AS net_balance,
    CASE
        WHEN total_net_paid > (SELECT avg(cs_net_paid_inc_tax) FROM catalog_sales) THEN 'HIGH'
        ELSE 'NORMAL'
    END AS net_paid_category
FROM combined
WHERE (total_net_paid IS NOT NULL AND total_net_paid > 1000)
   OR (total_refunded IS NOT NULL AND total_refunded > 500)
   OR (total_list_price IS NOT NULL AND total_list_price > 20000)
   OR (return_cnt IS NOT NULL AND return_cnt >= 2)
ORDER BY net_balance DESC NULLS LAST, customer_sk
LIMIT 100
