WITH cust_agg AS (
    SELECT
        c.c_birth_month,
        cd.cd_gender,
        c.c_birth_country,
        COUNT(DISTINCT c.c_customer_sk) AS cust_cnt,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_est,
        SUM(cd.cd_purchase_estimate) AS total_purchase_est
    FROM
        customer c
    JOIN
        customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_month IN (4,5,6,9,12)
        AND cd.cd_credit_rating = 'Good'
    GROUP BY
        c.c_birth_month,
        cd.cd_gender,
        c.c_birth_country
    HAVING
        COUNT(DISTINCT c.c_customer_sk) > 5
),
ws_stats AS (
    SELECT
        web_country,
        AVG(web_gmt_offset) AS avg_gmt_offset,
        COUNT(*) AS site_count
    FROM
        web_site
    WHERE
        web_open_date_sk >= 2450000
    GROUP BY
        web_country
)
SELECT
    ca.c_birth_month,
    ca.cd_gender,
    ca.c_birth_country,
    ca.cust_cnt,
    ca.avg_purchase_est,
    ca.total_purchase_est,
    ws.avg_gmt_offset,
    ws.site_count,
    RANK() OVER (ORDER BY ca.total_purchase_est DESC) AS purchase_rank
FROM
    cust_agg ca
LEFT JOIN
    ws_stats ws
    ON ca.c_birth_country = ws.web_country
ORDER BY
    purchase_rank
LIMIT 50
