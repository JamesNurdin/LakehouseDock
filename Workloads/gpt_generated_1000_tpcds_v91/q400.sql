WITH RECURSIVE high_profit_items (item_sk, brand, total_profit, lvl) AS (
    SELECT ws.ws_item_sk, i.i_brand, SUM(ws.ws_net_profit) AS total_profit, 1 AS lvl
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_item_sk, i.i_brand
    HAVING SUM(ws.ws_net_profit) > 1000

    UNION ALL

    SELECT i2.i_item_sk, h.brand, 0, h.lvl + 1
    FROM high_profit_items h
    JOIN item i2 ON i2.i_brand = h.brand
    WHERE i2.i_item_sk > h.item_sk
      AND h.lvl < 5
),
store_return_items (item_sk, brand) AS (
    SELECT DISTINCT sr.sr_item_sk, i2.i_brand
    FROM store_returns sr
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE r.r_reason_desc = 'Did not like the color'
      AND d_ret.d_year = 2001
),
candidate_items (item_sk, brand) AS (
    SELECT item_sk, brand FROM high_profit_items
    EXCEPT
    SELECT item_sk, brand FROM store_return_items
)
SELECT ci.brand,
       COUNT(*) AS item_count
FROM candidate_items ci
GROUP BY ci.brand
HAVING COUNT(*) > 5
ORDER BY item_count DESC
LIMIT 100
