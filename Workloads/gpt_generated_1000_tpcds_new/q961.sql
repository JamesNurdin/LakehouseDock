WITH base AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_type,
        cp.cp_catalog_page_number,
        d.d_year,
        d.d_date,
        d.d_following_holiday,
        ws.web_site_sk,
        ws.web_name,
        ws.web_gmt_offset
    FROM catalog_page cp
    FULL OUTER JOIN date_dim d
        ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE cp.cp_type IN ('quarterly', 'monthly')
      AND d.d_year = 2002
      AND ws.web_gmt_offset > -5.00
),
union_set AS (
    SELECT
        cp_catalog_page_sk,
        cp_type,
        cp_catalog_page_number,
        d_year,
        web_site_sk
    FROM base
    WHERE d_following_holiday = 'N'
    UNION
    SELECT
        cp_catalog_page_sk,
        cp_type,
        cp_catalog_page_number,
        d_year,
        web_site_sk
    FROM base
    WHERE d_following_holiday = 'Y'
),
except_set AS (
    SELECT cp_catalog_page_sk FROM catalog_page WHERE cp_catalog_page_number = 20
    EXCEPT
    SELECT cp_catalog_page_sk FROM catalog_page WHERE cp_type = 'bi-annual'
)
SELECT
    us.d_year,
    COUNT(DISTINCT us.cp_catalog_page_sk) AS distinct_page_cnt,
    COUNT(DISTINCT us.web_site_sk)      AS distinct_site_cnt,
    AVG(CASE WHEN us.cp_type = 'quarterly' THEN us.cp_catalog_page_number END) AS avg_quarterly_page_num,
    MAX(CASE WHEN us.cp_type = 'monthly'   THEN us.cp_catalog_page_number END) AS max_monthly_page_num,
    SUM(CASE WHEN us.cp_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM except_set) THEN 0 ELSE 1 END) AS pages_not_in_except
FROM union_set us
GROUP BY us.d_year
ORDER BY us.d_year DESC
LIMIT 100
