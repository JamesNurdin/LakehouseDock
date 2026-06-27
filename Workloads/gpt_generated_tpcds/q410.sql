WITH unified_returns AS (
    SELECT 
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_returned_time_sk AS return_time_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_reason_sk AS reason_sk,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        'catalog' AS return_type
    FROM catalog_returns cr
    UNION ALL
    SELECT 
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_reason_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        'store' AS return_type
    FROM store_returns sr
    UNION ALL
    SELECT 
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_reason_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        'web' AS return_type
    FROM web_returns wr
)
SELECT 
    d.d_year,
    d.d_month_seq,
    i.i_category,
    r.r_reason_desc,
    ur.return_type,
    SUM(ur.return_quantity) AS total_quantity,
    SUM(ur.return_amount) AS total_amount,
    SUM(ur.net_loss) AS total_net_loss,
    AVG(ur.net_loss) AS avg_net_loss
FROM unified_returns ur
JOIN date_dim d ON ur.return_date_sk = d.d_date_sk
JOIN item i ON ur.item_sk = i.i_item_sk
JOIN reason r ON ur.reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, d.d_month_seq, i.i_category, r.r_reason_desc, ur.return_type
ORDER BY total_net_loss DESC
LIMIT 50
