WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_net_loss,
        cp.cp_description,
        cp.cp_type,
        cc.cc_name,
        cc.cc_call_center_id,
        d.d_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND regexp_like(cp.cp_description, '(?i)promo')
      AND cp.cp_description LIKE '%discount%'
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cp.cp_type,
    concat(cc.cc_name, '_', cp.cp_type) AS combined_name,
    sum(fr.cr_net_loss) AS total_net_loss,
    count(*) AS return_count,
    avg(fr.cr_net_loss) AS avg_net_loss,
    (
        SELECT avg(cr_sub.cr_net_loss)
        FROM catalog_returns cr_sub
        JOIN date_dim d_sub ON cr_sub.cr_returned_date_sk = d_sub.d_date_sk
        WHERE d_sub.d_year = 2001
    ) AS overall_avg_net_loss,
    w.word,
    count(w.word) AS word_cnt
FROM filtered_returns fr
JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
CROSS JOIN UNNEST(split(cp.cp_description, ' ')) AS w(word)
WHERE w.word <> ''
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cp.cp_type,
    concat(cc.cc_name, '_', cp.cp_type),
    w.word
ORDER BY total_net_loss DESC
LIMIT 100
