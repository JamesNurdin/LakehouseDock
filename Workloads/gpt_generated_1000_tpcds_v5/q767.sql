WITH filtered_pages AS (
    SELECT DISTINCT
        cp_catalog_page_sk,
        cp_department,
        cp_description,
        cp_start_date_sk,
        cp_end_date_sk,
        regexp_extract(cp_description, '(\\w+)') AS first_word,
        regexp_extract(cp_description, '(services|girls|Poor)', 1) AS keyword_match
    FROM catalog_page
    WHERE cp_description LIKE '%services%'
      AND regexp_like(cp_description, '\\bservices\\b')
)
SELECT
    CONCAT(fp.cp_department, ':', fp.first_word) AS dept_first_word,
    fp.keyword_match,
    DATE_TRUNC('quarter', d.d_date) AS quarter_start,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
FROM filtered_pages fp
JOIN date_dim d ON fp.cp_end_date_sk = d.d_date_sk
JOIN web_returns wr ON d.d_date_sk = wr.wr_returned_date_sk
WHERE d.d_year = 2001
GROUP BY
    CONCAT(fp.cp_department, ':', fp.first_word),
    fp.keyword_match,
    DATE_TRUNC('quarter', d.d_date)
ORDER BY total_return_amount DESC
LIMIT 100
