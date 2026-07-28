WITH agg_store_sales AS (
    SELECT ss_cdemo_sk,
           SUM(ss_net_paid) AS total_store_sales,
           SUM(ss_net_profit) AS total_store_profit
    FROM store_sales
    GROUP BY ss_cdemo_sk
),
agg_web_sales AS (
    SELECT ws_bill_cdemo_sk,
           SUM(ws_net_paid) AS total_web_sales,
           SUM(ws_net_profit) AS total_web_profit
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
)
SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    ss.total_store_sales,
    ws.total_web_sales,
    (COALESCE(ss.total_store_sales, 0) + COALESCE(ws.total_web_sales, 0)) AS total_combined_sales,
    RANK() OVER (PARTITION BY cd.cd_education_status ORDER BY (COALESCE(ss.total_store_sales, 0) + COALESCE(ws.total_web_sales, 0)) DESC) AS sales_rank,
    r.r_reason_desc,
    sm.sm_ship_mode_id,
    sm.sm_code,
    cr.cr_return_amount,
    cr.cr_returned_date_sk
FROM customer_demographics cd
LEFT JOIN agg_store_sales ss
    ON cd.cd_demo_sk = ss.ss_cdemo_sk
LEFT JOIN agg_web_sales ws
    ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
LEFT JOIN catalog_returns cr
    ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cd.cd_education_status IN ('College', 'Advanced Degree')
  AND cd.cd_purchase_estimate > 3000
  AND sm.sm_code = 'AIR'
  AND cr.cr_return_amount > 1000
  AND r.r_reason_desc LIKE '%defect%'
ORDER BY sales_rank, cd.cd_demo_sk
LIMIT 100
