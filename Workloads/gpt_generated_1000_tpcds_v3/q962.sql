WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_catalog_page_sk,
        cr.cr_return_amount
    FROM catalog_returns cr
    INNER JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE
        regexp_like(cp.cp_description, '(?i)exciting')
        AND i.i_item_desc LIKE '%size%'
        AND d.d_fy_year = 1919
        AND d.d_month_seq BETWEEN 1200 AND 1220
),
brand_agg AS (
    SELECT
        i.i_brand,
        regexp_extract(cp.cp_description, '^(\\w+)', 1) AS first_word_of_desc,
        concat(i.i_item_id, '-', i.i_product_name) AS item_key,
        substring(i.i_product_name, 1, 15) AS short_product_name,
        sum(fr.cr_return_amount) AS total_return_amount,
        count(*) AS return_count
    FROM filtered_returns fr
    INNER JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN item i ON fr.cr_item_sk = i.i_item_sk
    GROUP BY
        i.i_brand,
        regexp_extract(cp.cp_description, '^(\\w+)', 1),
        concat(i.i_item_id, '-', i.i_product_name),
        substring(i.i_product_name, 1, 15)
)
SELECT
    i_brand,
    first_word_of_desc,
    item_key,
    short_product_name,
    total_return_amount,
    return_count,
    rank() OVER (ORDER BY total_return_amount DESC) AS brand_return_rank
FROM brand_agg
ORDER BY total_return_amount DESC
LIMIT 100
