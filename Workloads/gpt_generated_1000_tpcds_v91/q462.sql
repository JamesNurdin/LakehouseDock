WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_warehouse_sk,
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_description,
        cp.cp_type,
        cp.cp_department,
        w.w_warehouse_name,
        cr.cr_reason_sk,
        split(cp.cp_description, '\\s+') AS description_words,
        CONCAT(cp.cp_type, ':', cp.cp_department) AS type_dept
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cp.cp_type LIKE 'C%'
      AND regexp_like(cp.cp_description, '\\d{4}')
)
SELECT
    w_warehouse_name,
    COUNT(DISTINCT cp_catalog_page_sk) AS distinct_pages,
    COUNT(DISTINCT type_dept) AS distinct_type_depts,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_amount) AS avg_return_amount,
    CASE
        WHEN SUM(cr_return_amount) > 10000 THEN 'High'
        ELSE 'Low'
    END AS return_level,
    SUM(CASE WHEN word = 'return' THEN 1 ELSE 0 END) AS return_word_appearances,
    (SELECT AVG(cr3.cr_return_amount)
       FROM catalog_returns cr3
       WHERE cr3.cr_warehouse_sk = fr.cr_warehouse_sk) AS avg_return_amount_warehouse,
    MAX(CAST(regexp_extract(cp_catalog_page_id, '([0-9]+)', 1) AS integer)) AS max_page_number
FROM filtered_returns fr
CROSS JOIN UNNEST(fr.description_words) AS u(word)
GROUP BY w_warehouse_name, fr.cr_warehouse_sk
ORDER BY total_return_amount DESC
