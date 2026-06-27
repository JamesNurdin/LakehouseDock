WITH catalog AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
),
web AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
)
SELECT
    reason_desc,
    d_year,
    d_month_seq,
    category,
    sum(net_loss) FILTER (WHERE source = 'catalog') AS total_catalog_net_loss,
    sum(net_loss) FILTER (WHERE source = 'web') AS total_web_net_loss,
    sum(net_loss) AS total_net_loss
FROM (
    SELECT reason_desc, d_year, d_month_seq, category, net_loss, 'catalog' AS source FROM catalog
    UNION ALL
    SELECT reason_desc, d_year, d_month_seq, category, net_loss, 'web' AS source FROM web
) t
GROUP BY reason_desc, d_year, d_month_seq, category
ORDER BY total_net_loss DESC
LIMIT 20
