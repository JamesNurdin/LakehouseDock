WITH cat AS (
    SELECT
        i.i_brand AS brand,
        i.i_item_desc AS item_desc,
        CASE
            WHEN cr.cr_return_amount > 1000 THEN 'High'
            WHEN cr.cr_return_amount > 0 THEN 'Low'
            ELSE 'None'
        END AS return_level,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS qty,
        regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS first_word,
        cc.cc_state AS state
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
      AND cc.cc_state LIKE 'C%'
),
web AS (
    SELECT
        i.i_brand AS brand,
        i.i_item_desc AS item_desc,
        CASE
            WHEN wr.wr_return_amt > 500 THEN 'High'
            WHEN wr.wr_return_amt > 0 THEN 'Low'
            ELSE 'None'
        END AS return_level,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_quantity AS qty,
        regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS first_word,
        wp.wp_url AS page_url
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE wp.wp_url LIKE '%/promo%'
      AND regexp_like(wp.wp_url, '/promo[0-9]{2}')
)
SELECT
    brand,
    return_level,
    COUNT(*) AS return_cnt,
    SUM(return_amount) AS total_return_amount,
    AVG(qty) AS avg_qty,
    MAX(first_word) AS sample_word
FROM (
    SELECT brand, return_level, return_amount, qty, first_word FROM cat
    UNION ALL
    SELECT brand, return_level, return_amount, qty, first_word FROM web
) u
GROUP BY brand, return_level
HAVING SUM(return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
