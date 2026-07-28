/*
Goal: Produce a summary of catalog pages that started in 2001 for California web sites, showing counts and totals per department, quarter and web site, with subtotal rows, a ranking of departments by total catalog number, and a distinct page count.
*/
WITH joined_data AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_id,
        d_start.d_quarter_name,
        d_start.d_year,
        ws.web_name,
        ws.web_state,
        ws.web_gmt_offset
    FROM catalog_page cp
    JOIN date_dim d_start
      ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d_start.d_date_sk
    WHERE d_start.d_year = 2001
      AND cp.cp_catalog_number >= 10
      AND ws.web_state = 'CA'
      AND ws.web_gmt_offset > 0
)
SELECT
    jd.cp_department,
    jd.d_quarter_name,
    jd.web_name,
    COUNT(*) AS page_cnt,
    COUNT(DISTINCT jd.cp_catalog_page_id) AS distinct_page_cnt,
    SUM(jd.cp_catalog_number) AS total_catalog_number,
    ROW_NUMBER() OVER (
        PARTITION BY jd.cp_department
        ORDER BY SUM(jd.cp_catalog_number) DESC
    ) AS dept_rank
FROM joined_data jd
GROUP BY GROUPING SETS (
    (jd.cp_department, jd.d_quarter_name, jd.web_name),
    (jd.cp_department, jd.d_quarter_name),
    (jd.cp_department),
    ()
)
ORDER BY dept_rank ASC, jd.cp_department
LIMIT 100
