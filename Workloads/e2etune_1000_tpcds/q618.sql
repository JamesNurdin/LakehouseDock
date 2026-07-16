WITH agg AS (
    SELECT
        s.s_market_id AS market_id,
        s.s_market_desc AS market_desc,
        w.web_name AS website_name,
        COUNT(DISTINCT cp.cp_catalog_page_sk) AS distinct_catalog_pages,
        SUM(s.s_floor_space) AS total_floor_space,
        AVG(s.s_tax_percentage) AS avg_store_tax,
        AVG(w.web_tax_percentage) AS avg_website_tax
    FROM store s
    JOIN web_site w ON s.s_market_id = w.web_mkt_id
    JOIN catalog_page cp ON cp.cp_start_date_sk = s.s_closed_date_sk
    WHERE s.s_state = 'CA'
      AND w.web_state = 'CA'
      AND cp.cp_department = 'DEPARTMENT'
      AND cp.cp_catalog_number IN (1, 2, 3)
    GROUP BY s.s_market_id, s.s_market_desc, w.web_name
)
SELECT
    market_id,
    market_desc,
    website_name,
    distinct_catalog_pages,
    total_floor_space,
    avg_store_tax,
    avg_website_tax,
    RANK() OVER (ORDER BY total_floor_space DESC) AS floor_space_rank
FROM agg
ORDER BY total_floor_space DESC
LIMIT 10
