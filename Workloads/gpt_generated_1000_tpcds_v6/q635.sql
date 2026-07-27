WITH demo_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_education_status,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_fee) AS total_fee,
        COUNT(*) AS return_cnt,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(sr.sr_return_amt) DESC) AS gender_return_rank
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_employed_count >= 2
      AND sr.sr_return_amt > 0
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_education_status
),
web_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_education_status,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_sales_rank
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE cd.cd_education_status LIKE '%Degree%'
      AND ws.ws_net_paid > 0
      AND ws_site.web_state = 'CA'
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_education_status
)
SELECT
    cd_demo_sk,
    cd_gender,
    cd_education_status,
    'store_return' AS metric_type,
    total_return_amt AS metric_value,
    gender_return_rank AS rank
FROM demo_agg
WHERE return_cnt >= 5
UNION ALL
SELECT
    cd_demo_sk,
    cd_gender,
    cd_education_status,
    'web_sales' AS metric_type,
    total_net_paid AS metric_value,
    gender_sales_rank AS rank
FROM web_agg
WHERE sales_cnt >= 5
ORDER BY metric_type, metric_value DESC
LIMIT 100
