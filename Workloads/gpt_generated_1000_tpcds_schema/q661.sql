WITH sales_agg AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date_sk, d.d_date, cd.cd_gender
),
returns_agg AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        cd.cd_gender,
        SUM(cr.cr_return_amount) AS total_returns
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date_sk, d.d_date, cd.cd_gender
)
-- First part uses a FULL OUTER JOIN between the two aggregated CTEs
SELECT
    COALESCE(sa.d_date, ra.d_date) AS report_date,
    COALESCE(sa.cd_gender, ra.cd_gender) AS gender,
    sa.total_sales,
    ra.total_returns,
    (
        SELECT SUM(cr3.cr_return_amount)
        FROM catalog_returns cr3
        WHERE cr3.cr_returned_date_sk = COALESCE(sa.d_date_sk, ra.d_date_sk)
    ) AS total_return_amount_for_date,
    ROW_NUMBER() OVER (ORDER BY COALESCE(sa.d_date, ra.d_date)) AS rn
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.d_date_sk = ra.d_date_sk
   AND sa.cd_gender = ra.cd_gender

UNION ALL

-- Second part pulls web site opening information for the same year
SELECT
    d.d_date AS report_date,
    CAST(NULL AS varchar) AS gender,
    CAST(NULL AS decimal(7,2)) AS total_sales,
    CAST(NULL AS decimal(7,2)) AS total_returns,
    CAST(NULL AS decimal(7,2)) AS total_return_amount_for_date,
    ROW_NUMBER() OVER (ORDER BY d.d_date) AS rn
FROM web_site ws
JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001

ORDER BY report_date, gender
