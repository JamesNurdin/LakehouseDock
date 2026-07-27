WITH store_ret AS (
    SELECT
        d.d_year,
        d.d_date_sk,
        i.i_brand,
        r.r_reason_desc,
        sr.sr_return_quantity AS quantity,
        sr.sr_return_amt AS return_amt,
        sr.sr_net_loss AS net_loss,
        CASE WHEN sr.sr_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'BrandX'
      AND r.r_reason_desc LIKE '%price%'
),
catalog_ret AS (
    SELECT
        d.d_year,
        d.d_date_sk,
        i.i_brand,
        r.r_reason_desc,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS return_amt,
        cr.cr_net_loss AS net_loss,
        CASE WHEN cr.cr_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'BrandX'
      AND r.r_reason_desc LIKE '%price%'
      AND cc.cc_state = 'CA'
),
web_ret AS (
    SELECT
        d.d_year,
        d.d_date_sk,
        i.i_brand,
        r.r_reason_desc,
        wr.wr_return_quantity AS quantity,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss,
        CASE WHEN wr.wr_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'BrandX'
      AND r.r_reason_desc LIKE '%price%'
)
SELECT
    u.d_year,
    u.i_brand,
    u.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(u.quantity) AS total_quantity,
    SUM(u.return_amt) AS total_return_amount,
    SUM(u.net_loss) AS total_net_loss,
    AVG(u.net_loss) AS avg_net_loss,
    SUM(CASE WHEN u.net_loss > 1000 THEN 1 ELSE 0 END) AS high_loss_cnt
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM web_ret
) AS u
WHERE EXISTS (
    SELECT 1
    FROM web_site ws
    WHERE ws.web_open_date_sk = u.d_date_sk
      AND ws.web_city = 'San Francisco'
      AND ws.web_street_type = 'Pkwy'
)
GROUP BY u.d_year, u.i_brand, u.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
