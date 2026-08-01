WITH
    -- Returns per item where the color starts with "r"
    ret_a AS (
        SELECT
            i.i_item_sk,
            i.i_item_id,
            i.i_color,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt,
            regexp_extract(i.i_item_id, '([A-Z]+)', 1) AS prefix_code
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE regexp_like(i.i_color, '^r')
        GROUP BY
            i.i_item_sk,
            i.i_item_id,
            i.i_color,
            regexp_extract(i.i_item_id, '([A-Z]+)', 1)
    ),
    -- Returns per item where the color ends with "e"
    ret_b AS (
        SELECT
            i.i_item_sk,
            i.i_item_id,
            i.i_color,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE i.i_color LIKE '%e'
        GROUP BY i.i_item_sk, i.i_item_id, i.i_color
    ),
    -- Customers who refunded a large amount
    high_return_customers AS (
        SELECT DISTINCT cr.cr_refunded_customer_sk AS cust_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 200
    ),
    -- High‑income customers with a Gmail address
    high_income_customers AS (
        SELECT DISTINCT c.c_customer_sk AS cust_sk
        FROM customer c
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ib.ib_upper_bound >= 150000
          AND regexp_like(c.c_email_address, '@gmail\\.com$')
    ),
    -- Intersection of the two customer sets
    common_customers AS (
        SELECT cust_sk FROM high_return_customers
        INTERSECT
        SELECT cust_sk FROM high_income_customers
    ),
    -- Extract the first word from the item description using a LATERAL sub‑query
    item_desc_lateral AS (
        SELECT
            i.i_item_sk,
            i.i_item_desc,
            t.extracted_word
        FROM item i
        CROSS JOIN LATERAL (
            SELECT regexp_extract(i.i_item_desc, '(\\w+)', 1) AS extracted_word
        ) t
        WHERE i.i_item_desc IS NOT NULL
    ),
    -- Union of the two return aggregations (distinct rows only)
    union_ret AS (
        SELECT i_item_sk, i_item_id, i_color, total_return_amount, return_cnt FROM ret_a
        UNION
        SELECT i_item_sk, i_item_id, i_color, total_return_amount, return_cnt FROM ret_b
    ),
    -- Full outer join to keep items that appear in only one side of the union
    full_joined AS (
        SELECT
            COALESCE(u.i_item_sk, d.i_item_sk) AS item_sk,
            u.i_item_id,
            u.i_color,
            u.total_return_amount,
            u.return_cnt,
            d.i_item_desc,
            d.extracted_word
        FROM union_ret u
        FULL OUTER JOIN item_desc_lateral d
            ON u.i_item_sk = d.i_item_sk
    )
SELECT
    fj.item_sk,
    fj.i_item_id,
    fj.i_color,
    fj.total_return_amount,
    fj.return_cnt,
    fj.i_item_desc,
    fj.extracted_word,
    concat(fj.i_color, '-', fj.extracted_word) AS color_word_concat,
    substring(fj.i_item_id, 1, 4) AS item_id_prefix,
    (SELECT COUNT(*) FROM common_customers) AS common_customer_cnt
FROM full_joined fj
WHERE fj.i_color IS NOT NULL
ORDER BY fj.total_return_amount DESC
LIMIT 100
