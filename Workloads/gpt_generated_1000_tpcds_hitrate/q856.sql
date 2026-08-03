WITH cte_store_demo AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_refunded_cash,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_store_sk IN (
        SELECT sr2.sr_store_sk
        FROM store_returns sr2
        WHERE sr2.sr_return_ship_cost > 1000
    )
)
SELECT
    combined.sr_store_sk,
    combined.total_return_amt,
    combined.avg_refunded_cash,
    combined.distinct_customers,
    combined.distinct_education_statuses,
    ROW_NUMBER() OVER (ORDER BY combined.total_return_amt DESC) AS rn
FROM (
    SELECT
        sd.sr_store_sk,
        SUM(sd.sr_return_amt) AS total_return_amt,
        AVG(sd.sr_refunded_cash) AS avg_refunded_cash,
        COUNT(DISTINCT sd.sr_customer_sk) AS distinct_customers,
        COUNT(DISTINCT sd.cd_education_status) AS distinct_education_statuses
    FROM cte_store_demo sd
    WHERE sd.cd_education_status = 'College'
      AND sd.cd_purchase_estimate > 3000
    GROUP BY sd.sr_store_sk

    UNION ALL

    SELECT
        sd.sr_store_sk,
        SUM(sd.sr_return_amt) AS total_return_amt,
        AVG(sd.sr_refunded_cash) AS avg_refunded_cash,
        COUNT(DISTINCT sd.sr_customer_sk) AS distinct_customers,
        COUNT(DISTINCT sd.cd_education_status) AS distinct_education_statuses
    FROM cte_store_demo sd
    WHERE sd.cd_education_status = '4 yr Degree'
      AND sd.cd_purchase_estimate <= 5000
    GROUP BY sd.sr_store_sk
) AS combined
ORDER BY combined.total_return_amt DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
