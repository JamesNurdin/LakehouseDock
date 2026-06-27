WITH all_returns AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        i.i_product_name AS product_name,
        r.r_reason_desc AS reason_desc,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk

    UNION ALL

    SELECT
        sr.sr_item_sk AS item_sk,
        i.i_product_name AS product_name,
        r.r_reason_desc AS reason_desc,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk

    UNION ALL

    SELECT
        wr.wr_item_sk AS item_sk,
        i.i_product_name AS product_name,
        r.r_reason_desc AS reason_desc,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
)
SELECT
    item_sk,
    product_name,
    reason_desc,
    SUM(net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(net_loss) AS avg_net_loss
FROM all_returns
GROUP BY item_sk, product_name, reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
