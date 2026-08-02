WITH pages_with_words AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_description,
        split(cp.cp_description, ' ') AS words,
        regexp_extract(cp.cp_description, '(\\w+)', 1) AS first_word,
        CASE
            WHEN regexp_like(cp.cp_description, '(?i)sale') THEN 'sale'
            ELSE 'other'
        END AS description_category
    FROM catalog_page cp
    WHERE regexp_like(cp.cp_description, '(?i)sale|discount')
)

SELECT
    record_type,
    store_year,
    store_name,
    total_orders,
    total_amount,
    distinct_word_cnt,
    concatenated_label
FROM (
    SELECT
        'sales' AS record_type,
        d_sold.d_year AS store_year,
        s.s_store_name AS store_name,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_ext_sales_price) AS total_amount,
        COUNT(DISTINCT w.word) AS distinct_word_cnt,
        concat(s.s_store_name, ' - ', CAST(d_sold.d_year AS VARCHAR)) AS concatenated_label
    FROM pages_with_words pw
    JOIN catalog_sales cs
        ON cs.cs_catalog_page_sk = pw.cp_catalog_page_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN UNNEST(pw.words) AS w(word)
        ON TRUE
    WHERE s.s_store_name LIKE '%Market%'
      AND cs.cs_ext_sales_price > (
          SELECT AVG(cs2.cs_ext_sales_price)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
      )
    GROUP BY d_sold.d_year, s.s_store_name
    HAVING SUM(cs.cs_ext_sales_price) > 10000

    UNION ALL

    SELECT
        'returns' AS record_type,
        d_ret.d_year AS store_year,
        s_ret.s_store_name AS store_name,
        COUNT(DISTINCT cr.cr_order_number) AS total_orders,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(DISTINCT w_ret.word) AS distinct_word_cnt,
        concat(s_ret.s_store_name, ' - ', CAST(d_ret.d_year AS VARCHAR)) AS concatenated_label
    FROM pages_with_words pw
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = pw.cp_catalog_page_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s_ret
        ON s_ret.s_closed_date_sk = d_ret.d_date_sk
    LEFT JOIN UNNEST(pw.words) AS w_ret(word)
        ON TRUE
    WHERE s_ret.s_store_name LIKE 'A%'
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = cr.cr_reason_sk
            AND regexp_like(r.r_reason_desc, '(?i)damaged')
      )
    GROUP BY d_ret.d_year, s_ret.s_store_name
    HAVING SUM(cr.cr_return_amount) > 5000
) final_result
ORDER BY total_amount DESC
LIMIT 100
