WITH store AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 18
    GROUP BY d.d_year, d.d_month_seq, i.i_category, r.r_reason_desc
),
catalog AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 18
    GROUP BY d.d_year, d.d_month_seq, i.i_category, r.r_reason_desc
),
web AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 18
    GROUP BY d.d_year, d.d_month_seq, i.i_category, r.r_reason_desc
),
combined AS (
    SELECT d_year, d_month_seq, i_category, r_reason_desc, net_loss, return_cnt FROM store
    UNION ALL
    SELECT d_year, d_month_seq, i_category, r_reason_desc, net_loss, return_cnt FROM catalog
    UNION ALL
    SELECT d_year, d_month_seq, i_category, r_reason_desc, net_loss, return_cnt FROM web
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    r_reason_desc,
    SUM(net_loss) AS total_net_loss,
    SUM(return_cnt) AS total_returns
FROM combined
GROUP BY d_year, d_month_seq, i_category, r_reason_desc
ORDER BY total_net_loss DESC, d_year, d_month_seq, i_category
