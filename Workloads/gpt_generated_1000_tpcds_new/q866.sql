WITH sampled_cr AS (
    SELECT *
    FROM catalog_returns TABLESAMPLE BERNOULLI (10)
),
reason_words AS (
    SELECT
        r.r_reason_sk,
        word
    FROM reason r
    CROSS JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
),
joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        r.r_reason_sk,
        r.r_reason_desc,
        rw.word AS reason_word
    FROM sampled_cr cr
    FULL OUTER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN reason_words rw
        ON r.r_reason_sk = rw.r_reason_sk
    WHERE
        regexp_like(coalesce(r.r_reason_desc, ''), 'damaged')
        AND r.r_reason_desc LIKE '%defect%'
)

SELECT
    reason_word,
    concat('Word: ', reason_word) AS word_label,
    COUNT(DISTINCT cr_returned_date_sk) AS days_with_returns,
    SUM(cr_return_quantity) AS total_quantity,
    AVG(cr_return_amount) AS avg_return_amount,
    (
        SELECT SUM(wr.wr_net_loss)
        FROM web_returns wr
        WHERE wr.wr_reason_sk = joined.r_reason_sk
    ) AS web_net_loss_for_reason
FROM joined
WHERE reason_word IS NOT NULL
GROUP BY reason_word, joined.r_reason_sk, concat('Word: ', reason_word)
ORDER BY total_quantity DESC
LIMIT 100
