WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_product_name LIKE 'A%'
),
enriched AS (
    SELECT
        fr.cr_return_amount,
        fr.cr_net_loss,
        r.r_reason_desc,
        t.t_hour,
        regexp_extract(r.r_reason_desc, '^([^ ]+)', 1) AS first_word
    FROM filtered_returns fr
    JOIN tpcds.reason r
        ON fr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.time_dim t
        ON fr.cr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)warranty')
)
SELECT
    r_reason_desc,
    t_hour,
    first_word,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM enriched
GROUP BY ROLLUP (r_reason_desc, t_hour, first_word)
ORDER BY r_reason_desc ASC NULLS LAST,
         t_hour ASC NULLS LAST
