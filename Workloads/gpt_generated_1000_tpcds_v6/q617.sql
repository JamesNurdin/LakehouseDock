/* goal: Analyze store and catalog return performance by customer gender, focusing on high‑value, college‑educated customers with recent fee‑related returns */
WITH filtered_store AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_fee,
        sr.sr_cdemo_sk,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cd.cd_dep_college_count
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 5000                -- high purchase estimate
      AND cd.cd_dep_college_count <= 2                -- few or no college‑educated dependents
      AND sr.sr_fee > 20.00                           -- fee above $20
      AND sr.sr_return_quantity = 1                  -- single‑item returns
)
SELECT
    fs.cd_gender,
    COUNT(DISTINCT fs.sr_ticket_number) AS ticket_cnt,
    SUM(fs.sr_return_amt) AS total_store_return,
    SUM(cr.cr_return_amount) AS total_catalog_return,
    AVG(fs.sr_return_amt) AS avg_store_return,
    (
        SELECT AVG(cr_sub.cr_return_amount)
        FROM catalog_returns cr_sub
    ) AS overall_avg_catalog_return
FROM filtered_store fs
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_cdemo_sk = fs.cd_demo_sk
   AND cr.cr_return_tax < 40.00                       -- modest tax on catalog return
WHERE cr.cr_return_amount IS NOT NULL                 -- keep only matching catalog returns
GROUP BY fs.cd_gender
ORDER BY total_store_return DESC
LIMIT 100
