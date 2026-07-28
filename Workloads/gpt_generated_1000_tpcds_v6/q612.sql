WITH sales AS (
    SELECT
        ss.ss_item_sk,
        i.i_manufact,
        i.i_brand,
        i.i_category,
        i.i_color,
        td.t_shift,
        i.i_item_id,
        ss.ss_ext_sales_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
      AND i.i_color LIKE 's%'
      AND regexp_like(i.i_color, '^s')
),
returns AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_return_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
)
SELECT
    s.i_manufact,
    s.i_brand,
    s.i_category,
    CONCAT(s.i_brand, '-', s.i_category) AS brand_category,
    REGEXP_EXTRACT(s.i_item_id, '(\\d+)$', 1) AS item_id_suffix,
    SUM(s.ss_ext_sales_price) AS total_sales_amount,
    SUM(COALESCE(r.cr_return_amount, 0)) AS total_return_amount,
    CASE
        WHEN SUM(s.ss_ext_sales_price) > 10000 THEN 'big'
        ELSE 'small'
    END AS sales_size_flag
FROM sales s
LEFT JOIN returns r ON s.ss_item_sk = r.cr_item_sk
GROUP BY
    s.i_manufact,
    s.i_brand,
    s.i_category,
    CONCAT(s.i_brand, '-', s.i_category),
    REGEXP_EXTRACT(s.i_item_id, '(\\d+)$', 1)
ORDER BY total_sales_amount DESC
LIMIT 100
