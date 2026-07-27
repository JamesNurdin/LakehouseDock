WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        cp.cp_start_date_sk,
        regexp_extract(cp.cp_description, '(\\d{3})', 1) AS three_digit_code
    FROM catalog_page cp
    WHERE regexp_like(cp.cp_description, '\\d{3}')
      AND cp.cp_type LIKE 'C%'
)
SELECT
    concat(fp.cp_department, ' - ', fp.cp_type) AS dept_type,
    substr(d.d_day_name, 1, 3) AS day_abbr,
    COUNT(DISTINCT fp.cp_catalog_page_sk) AS distinct_pages,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_quantity) AS avg_quantity
FROM filtered_pages fp
JOIN date_dim d ON fp.cp_start_date_sk = d.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 1999
GROUP BY
    concat(fp.cp_department, ' - ', fp.cp_type),
    substr(d.d_day_name, 1, 3)
ORDER BY total_net_profit DESC
LIMIT 100
