WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word,
        CONCAT(i.i_category, '-', regexp_extract(i.i_item_desc, '(\\w+)', 1)) AS cat_word,
        SUM(ss.ss_ext_sales_price) AS total_amount,
        COUNT(*) AS cnt,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS flag
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'morning'
      AND i.i_item_desc LIKE '%PROD%'
      AND regexp_like(i.i_item_desc, '^\\w{3}')
    GROUP BY i.i_category,
             regexp_extract(i.i_item_desc, '(\\w+)', 1)
    HAVING SUM(ss.ss_ext_sales_price) > 500
),
returns_agg AS (
    SELECT
        r.r_reason_desc AS category,
        regexp_extract(r.r_reason_desc, '(\\w+)', 1) AS first_word,
        CONCAT(r.r_reason_desc, '-', regexp_extract(r.r_reason_desc, '(\\w+)', 1)) AS cat_word,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(*) AS cnt,
        CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS flag
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'evening'
      AND r.r_reason_desc LIKE '%damage%'
      AND regexp_like(r.r_reason_desc, 'damage')
    GROUP BY r.r_reason_desc,
             regexp_extract(r.r_reason_desc, '(\\w+)', 1)
    HAVING SUM(cr.cr_return_amount) > 500
)
SELECT category, first_word, cat_word, total_amount, cnt, flag
FROM sales_agg
UNION ALL
SELECT category, first_word, cat_word, total_amount, cnt, flag
FROM returns_agg
ORDER BY total_amount DESC, category ASC
LIMIT 100
