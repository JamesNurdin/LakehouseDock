WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_item_id,
        regexp_extract(i_item_desc, '(\\w+)', 1) AS first_word,
        concat('Item-', i_item_id) AS item_code
    FROM item
    WHERE regexp_like(i_item_desc, '.*[A-Z]{3}.*')
),
ranked_returns AS (
    SELECT
        r.r_reason_desc,
        c.c_customer_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        fi.first_word,
        fi.item_code,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN filtered_items fi ON cr.cr_item_sk = fi.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%price%'
      AND regexp_like(fi.i_item_desc, '^.*\\d{3}.*$')
    GROUP BY r.r_reason_desc, c.c_customer_id, fi.first_word, fi.item_code
)
SELECT
    r_reason_desc,
    c_customer_id,
    total_return_amount,
    first_word,
    item_code
FROM ranked_returns
WHERE rn <= 5
ORDER BY r_reason_desc, total_return_amount DESC
LIMIT 100
