WITH cp_agg AS (
    SELECT
        cp_catalog_number,
        cp_department,
        COUNT(*) AS page_cnt,
        MIN(cp_start_date_sk) AS min_start_sk
    FROM catalog_page
    WHERE cp_department IN ('Electronics', 'Books', 'Clothing', 'Home')
      AND cp_catalog_number BETWEEN 1 AND 20
    GROUP BY cp_catalog_number, cp_department
)
SELECT DISTINCT
    cp_agg.cp_department,
    cp_agg.cp_catalog_number,
    cp_agg.page_cnt,
    ws.web_name,
    d_start.d_date,
    RANK() OVER (PARTITION BY cp_agg.cp_department ORDER BY cp_agg.page_cnt DESC) AS dept_rank,
    ROW_NUMBER() OVER (ORDER BY cp_agg.page_cnt DESC) AS overall_row_num
FROM cp_agg
JOIN date_dim d_start
    ON cp_agg.min_start_sk = d_start.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_start.d_date_sk
WHERE ws.web_county = 'Walker County'
  AND ws.web_manager = 'Jimmy Pope'
  AND d_start.d_fy_quarter_seq = 16
  AND d_start.d_year = 2001
ORDER BY overall_row_num
LIMIT 100
