WITH sampled_store AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
),
store_reason AS (
    SELECT
        sr.sr_reason_sk,
        sr.sr_net_loss,
        r.r_reason_desc,
        r.r_reason_id,
        lr.first_word
    FROM sampled_store sr
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN LATERAL (
        SELECT regexp_extract(r.r_reason_desc, '(\\w+)', 1) AS first_word
    ) lr ON true
    WHERE r.r_reason_desc IS NOT NULL
      AND regexp_like(r.r_reason_desc, '^.*return.*$')
),
web_page_filtered AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_char_count,
        wp.wp_autogen_flag,
        wp.wp_type
    FROM web_page wp
    WHERE wp.wp_url LIKE 'http%://%example.com/%'
),
web_ret AS (
    SELECT
        wr.wr_web_page_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        r.r_reason_desc,
        r.r_reason_id
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    FULL OUTER JOIN web_page_filtered wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_autogen_flag = 'Y' OR wp.wp_autogen_flag IS NULL
),
store_reason_set AS (
    SELECT DISTINCT r_reason_id
    FROM store_reason
    WHERE sr_net_loss > 1000
),
web_ret_set AS (
    SELECT DISTINCT r_reason_id
    FROM web_ret
    WHERE wr_return_amt > 500
)
SELECT
    sr.r_reason_id,
    sr.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    CONCAT('Reason ', sr.r_reason_id) AS label,
    SUBSTRING(sr.r_reason_desc FROM 1 FOR 10) AS short_desc
FROM store_reason sr
RIGHT OUTER JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
GROUP BY sr.r_reason_id, sr.r_reason_desc
EXCEPT
SELECT
    r_id,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
FROM (
    SELECT r_reason_id AS r_id
    FROM web_ret_set
) t
LIMIT 100
