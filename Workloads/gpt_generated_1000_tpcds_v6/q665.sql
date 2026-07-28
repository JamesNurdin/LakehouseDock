WITH avg_cr_net_loss AS (
    SELECT AVG(cr_net_loss) AS avg_loss
    FROM catalog_returns
),
high_price_items AS (
    SELECT COUNT(*) AS cnt
    FROM item
    WHERE i_current_price > 100
)
SELECT
    'Store' AS return_channel,
    r.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_net_loss,
    hp.cnt AS high_price_item_count
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
CROSS JOIN high_price_items hp
WHERE sr.sr_net_loss > (SELECT avg_loss FROM avg_cr_net_loss)
GROUP BY r.r_reason_desc, hp.cnt

UNION ALL

SELECT
    'Catalog' AS return_channel,
    r.r_reason_desc,
    SUM(cr.cr_net_loss) AS total_net_loss,
    hp.cnt
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
CROSS JOIN high_price_items hp
WHERE cr.cr_net_loss > (SELECT avg_loss FROM avg_cr_net_loss)
GROUP BY r.r_reason_desc, hp.cnt

UNION ALL

SELECT
    'Web' AS return_channel,
    r.r_reason_desc,
    SUM(wr.wr_net_loss) AS total_net_loss,
    hp.cnt
FROM web_returns wr
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
CROSS JOIN high_price_items hp
WHERE wr.wr_net_loss > (SELECT avg_loss FROM avg_cr_net_loss)
GROUP BY r.r_reason_desc, hp.cnt

ORDER BY return_channel, total_net_loss DESC
LIMIT 100
