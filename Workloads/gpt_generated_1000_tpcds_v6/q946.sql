WITH high_inventory AS (
    SELECT i.inv_item_sk
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY i.inv_item_sk
    HAVING SUM(i.inv_quantity_on_hand) > 1000
)
SELECT
    r.r_reason_desc,
    'Catalog' AS channel,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    (SELECT AVG(cr3.cr_net_loss)
       FROM catalog_returns cr3
       WHERE cr3.cr_reason_sk = r.r_reason_sk) AS avg_loss_for_reason
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND EXISTS (
        SELECT 1
        FROM high_inventory hi
        WHERE hi.inv_item_sk = cr.cr_item_sk
    )
GROUP BY r.r_reason_sk, r.r_reason_desc
HAVING SUM(cr.cr_net_loss) > 0

UNION ALL

SELECT
    r.r_reason_desc,
    'Web' AS channel,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    (SELECT AVG(wr3.wr_net_loss)
       FROM web_returns wr3
       WHERE wr3.wr_reason_sk = r.r_reason_sk) AS avg_loss_for_reason
FROM web_returns wr
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND EXISTS (
        SELECT 1
        FROM high_inventory hi
        WHERE hi.inv_item_sk = wr.wr_item_sk
    )
GROUP BY r.r_reason_sk, r.r_reason_desc
HAVING SUM(wr.wr_net_loss) > 0

ORDER BY total_net_loss DESC, channel
LIMIT 100
