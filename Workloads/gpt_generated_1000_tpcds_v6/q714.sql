WITH high_cost_items AS (
    SELECT
        i_item_sk,
        i_brand,
        i_wholesale_cost
    FROM item
    WHERE i_wholesale_cost > 20
)
SELECT
    hci.i_brand,
    'Web' AS source_type,
    SUM(ws.ws_net_profit) AS total_amount,
    CASE WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = hci.i_item_sk
    ) AS metric_value
FROM high_cost_items hci
JOIN web_sales ws
    ON ws.ws_item_sk = hci.i_item_sk
WHERE ws.ws_ext_tax > 20
GROUP BY hci.i_brand, hci.i_item_sk

UNION ALL

SELECT
    hci.i_brand,
    'Return' AS source_type,
    SUM(sr.sr_net_loss) AS total_amount,
    CASE WHEN SUM(sr.sr_net_loss) > 50000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = hci.i_item_sk
    ) AS metric_value
FROM high_cost_items hci
JOIN store_returns sr
    ON sr.sr_item_sk = hci.i_item_sk
JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
WHERE r.r_reason_desc LIKE '%Damaged%'
  AND sr.sr_return_tax > 0
GROUP BY hci.i_brand, hci.i_item_sk
ORDER BY total_amount DESC, i_brand
LIMIT 100
