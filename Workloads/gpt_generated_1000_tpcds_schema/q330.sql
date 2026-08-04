WITH sr_agg AS (
    SELECT
        sr_customer_sk,
        sr_reason_sk,
        COUNT(*) AS returns_cnt,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_tax) AS avg_return_tax,
        MIN(sr_return_amt_inc_tax) AS min_return_inc_tax,
        MAX(sr_return_amt_inc_tax) AS max_return_inc_tax
    FROM tpcds.store_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE sr_return_quantity > 1
      AND sr_return_amt > 10.00
      AND sr_return_tax BETWEEN 1.00 AND 50.00
      AND sr_reversed_charge < 100.00
      AND sr_store_credit >= 0.00
      AND sr_return_ship_cost <= 20.00
    GROUP BY sr_customer_sk, sr_reason_sk
)
SELECT *
FROM (
    SELECT
        r.r_reason_desc,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(sa.returns_cnt) AS total_returns,
        SUM(sa.total_return_amt) AS total_return_amount,
        AVG(sa.avg_return_tax) AS avg_return_tax,
        MIN(sa.min_return_inc_tax) AS min_return_inc_tax,
        MAX(sa.max_return_inc_tax) AS max_return_inc_tax
    FROM sr_agg sa
    JOIN tpcds.customer c
        ON sa.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.reason r
        ON sa.sr_reason_sk = r.r_reason_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_current_addr_sk IN (297266, 1067875)
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND EXISTS (
            SELECT 1
            FROM tpcds.store_returns sr2
            WHERE sr2.sr_customer_sk = c.c_customer_sk
              AND sr2.sr_return_amt > 250.00
            LIMIT 1
        )
    GROUP BY r.r_reason_desc
    HAVING SUM(sa.total_return_amt) > 500.00

    UNION DISTINCT

    SELECT
        r.r_reason_desc,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(sa.returns_cnt) AS total_returns,
        SUM(sa.total_return_amt) AS total_return_amount,
        AVG(sa.avg_return_tax) AS avg_return_tax,
        MIN(sa.min_return_inc_tax) AS min_return_inc_tax,
        MAX(sa.max_return_inc_tax) AS max_return_inc_tax
    FROM sr_agg sa
    JOIN tpcds.customer c
        ON sa.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.reason r
        ON sa.sr_reason_sk = r.r_reason_sk
    WHERE c.c_birth_month = 7
      AND c.c_birth_day = 20
      AND c.c_preferred_cust_flag = 'N'
      AND r.r_reason_desc LIKE '%purchase%'
      AND sa.returns_cnt BETWEEN 3 AND 10
      AND sa.total_return_amt > 300.00
      AND EXISTS (
            SELECT 1
            FROM tpcds.store_returns sr4
            WHERE sr4.sr_customer_sk = c.c_customer_sk
              AND sr4.sr_fee > 5.00
            LIMIT 1
        )
    GROUP BY r.r_reason_desc
    HAVING COUNT(DISTINCT c.c_customer_id) >= 5
) combined
ORDER BY total_return_amount DESC
LIMIT 100
