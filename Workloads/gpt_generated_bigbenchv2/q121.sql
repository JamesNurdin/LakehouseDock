WITH page_lengths AS (
    SELECT
        w_web_page_id,
        w_web_page_name,
        w_web_page_type,
        LENGTH(w_web_page_name) AS name_len
    FROM web_pages
),
page_agg AS (
    SELECT
        pl.w_web_page_type,
        COUNT(*) AS total_pages,
        COUNT(DISTINCT pl.w_web_page_name) AS distinct_names,
        AVG(pl.name_len) AS avg_name_len,
        MAX(pl.name_len) AS max_name_len,
        MIN(pl.name_len) AS min_name_len,
        MAX(CASE WHEN pl.row_number = 1 THEN pl.w_web_page_name END) AS longest_page_name
    FROM (
        SELECT
            pl2.w_web_page_type,
            pl2.w_web_page_id,
            pl2.w_web_page_name,
            pl2.name_len,
            ROW_NUMBER() OVER (PARTITION BY pl2.w_web_page_type ORDER BY pl2.name_len DESC) AS row_number
        FROM page_lengths pl2
    ) pl
    GROUP BY pl.w_web_page_type
)
SELECT
    page_agg.w_web_page_type,
    page_agg.total_pages,
    page_agg.distinct_names,
    page_agg.avg_name_len,
    page_agg.max_name_len,
    page_agg.min_name_len,
    page_agg.longest_page_name,
    RANK() OVER (ORDER BY page_agg.total_pages DESC) AS type_rank
FROM page_agg
ORDER BY page_agg.total_pages DESC
