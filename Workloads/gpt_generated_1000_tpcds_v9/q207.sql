/*
Goal: Summarize catalog returns by catalog page for the year 2001, focusing on pages whose description contains the word "economic" and return reasons mentioning "damage". The query extracts textual features from the page description (first three words, a short snippet, a flag for the word "economic"), concatenates page identifiers, and computes return counts and monetary totals. It assigns a global row number ordered by total return amount.
*/
WITH filtered_returns AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_type,
        cp.cp_description,
        r.r_reason_desc,
        w.w_warehouse_name,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cp.cp_description LIKE '%economic%'
      AND r.r_reason_desc LIKE '%damage%'
),
aggregated AS (
    SELECT
        cp_catalog_page_id,
        cp_type,
        cp_description,
        r_reason_desc,
        w_warehouse_name,
        COUNT(DISTINCT cr_order_number) AS distinct_orders,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss
    FROM filtered_returns
    GROUP BY
        cp_catalog_page_id,
        cp_type,
        cp_description,
        r_reason_desc,
        w_warehouse_name
)
SELECT
    cp_catalog_page_id,
    cp_type,
    concat(cp_catalog_page_id, '-', cp_type) AS page_type_key,
    substr(cp_description, 1, 50) AS short_desc,
    regexp_extract(cp_description, '([A-Za-z]+ [A-Za-z]+ [A-Za-z]+)', 1) AS first_three_words,
    CASE WHEN regexp_like(cp_description, '(?i)economic') THEN 1 ELSE 0 END AS has_economic_word,
    r_reason_desc,
    w_warehouse_name,
    distinct_orders,
    total_return_amount,
    total_net_loss,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
