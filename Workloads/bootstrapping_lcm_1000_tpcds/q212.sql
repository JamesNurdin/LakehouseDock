WITH returns_by_date_reason AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_reason_sk AS reason_sk,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) AS sum_return_amt,
        SUM(cr.cr_net_loss) AS sum_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_reason_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    rbdr.return_cnt,
    rbdr.sum_return_amt,
    rbdr.sum_net_loss,
    s.s_market_manager,
    wp.wp_url,
    ROW_NUMBER() OVER (PARTITION BY d.d_year, r.r_reason_desc ORDER BY rbdr.sum_return_amt DESC) AS rank_by_return_amt
FROM returns_by_date_reason rbdr
JOIN date_dim d
    ON rbdr.return_date_sk = d.d_date_sk
JOIN reason r
    ON rbdr.reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2017
ORDER BY d.d_year, rank_by_return_amt
LIMIT 100
