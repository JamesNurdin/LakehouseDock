WITH agg_returns AS (
    SELECT
        cr_returning_cdemo_sk,
        cr_returning_addr_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr_return_tax) AS avg_tax
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_returning_cdemo_sk, cr_returning_addr_sk
)
SELECT
    cd.cd_education_status,
    ca.ca_state,
    SUM(ar.total_return_amount) AS education_state_return_total,
    AVG(ar.avg_tax) AS avg_tax_overall,
    COUNT(DISTINCT ar.cr_returning_cdemo_sk) AS distinct_demo_count
FROM agg_returns ar
JOIN customer_demographics cd
    ON ar.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON ar.cr_returning_addr_sk = ca.ca_address_sk
WHERE cd.cd_education_status IN ('Advanced Degree', 'College')
  AND cd.cd_dep_count <= 3
  AND ca.ca_state = 'CA'
GROUP BY cd.cd_education_status, ca.ca_state
HAVING SUM(ar.total_return_amount) > 5000
ORDER BY education_state_return_total DESC
LIMIT 100
