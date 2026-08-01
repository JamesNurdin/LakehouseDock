WITH page_website_daily AS (
    SELECT
        cp.cp_catalog_page_number,
        cp.cp_catalog_number,
        cp.cp_type,
        cp.cp_department,
        d_start.d_year,
        d_start.d_month_seq,
        d_start.d_fy_week_seq,
        d_end.d_fy_week_seq AS end_fy_week_seq,
        ws.web_site_id,
        ws.web_market_manager,
        ws.web_company_id
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_start.d_date_sk
    WHERE cp.cp_catalog_page_number IN (13, 15, 17)
      AND cp.cp_type = 'Catalog'
      AND d_start.d_year = 2001
      AND d_start.d_fy_week_seq >= 5
      AND d_end.d_fy_week_seq <= 12
      AND ws.web_company_id IN (1, 2, 3)
      AND ws.web_market_manager LIKE 'J%'
),
agg_by_manager_year AS (
    SELECT
        web_market_manager,
        d_year,
        COUNT(*) AS page_count,
        SUM(cp_catalog_number) AS total_catalog_number,
        AVG(cp_catalog_page_number) AS avg_page_number
    FROM page_website_daily
    GROUP BY web_market_manager, d_year
    HAVING COUNT(*) > 5
)
SELECT
    ag.web_market_manager,
    ag.d_year,
    ag.page_count,
    ag.total_catalog_number,
    ag.avg_page_number,
    ag.total_catalog_number * 1.0 / SUM(ag.total_catalog_number) OVER (PARTITION BY ag.d_year) AS pct_of_year_total
FROM agg_by_manager_year ag
WHERE ag.web_market_manager IN (
    SELECT DISTINCT web_market_manager
    FROM web_site
    WHERE web_market_manager LIKE 'J%'
      AND web_company_id = 2
)
ORDER BY ag.d_year DESC, pct_of_year_total DESC
