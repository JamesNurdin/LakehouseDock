WITH
    store_agg AS (
        SELECT
            i.i_item_sk,
            i.i_brand,
            i.i_item_desc,
            SUM(ss.ss_net_profit) AS store_net_profit,
            COUNT(*) AS store_txn_count,
            MAX(ss.ss_net_paid) AS max_store_payment
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        WHERE REGEXP_LIKE(i.i_item_desc, '^[A-Za-z]+[0-9]{2,}$')
          AND i.i_brand LIKE 'B%'
          AND t.t_hour BETWEEN 9 AND 17
        GROUP BY i.i_item_sk, i.i_brand, i.i_item_desc
    ),
    web_agg AS (
        SELECT
            i.i_item_sk,
            i.i_brand,
            i.i_item_desc,
            SUM(ws.ws_net_profit) AS web_net_profit,
            COUNT(*) AS web_txn_count,
            MAX(ws.ws_net_paid) AS max_web_payment
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
        WHERE REGEXP_LIKE(i.i_item_desc, '^[A-Za-z]+[0-9]{2,}$')
          AND w.web_name LIKE '%Shop%'
          AND t.t_hour BETWEEN 9 AND 17
        GROUP BY i.i_item_sk, i.i_brand, i.i_item_desc
    ),
    common_items AS (
        SELECT i_item_sk FROM store_agg
        INTERSECT
        SELECT i_item_sk FROM web_agg
    ),
    max_global_net_profit AS (
        SELECT MAX(profit) AS max_profit FROM (
            SELECT store_net_profit AS profit FROM store_agg
            UNION ALL
            SELECT web_net_profit AS profit FROM web_agg
        )
    )
SELECT
    'Store' AS channel,
    concat(i_brand, ' - ', i_item_desc) AS item_full_desc,
    store_net_profit AS net_profit,
    store_txn_count AS txn_count,
    (store_net_profit / max_global_net_profit.max_profit) * 100 AS profit_pct_of_max,
    CASE
        WHEN REGEXP_LIKE(i_item_desc, '.*[Gg]adget.*') THEN 'Gadget'
        ELSE 'Other'
    END AS item_category_group
FROM store_agg
JOIN common_items ci ON store_agg.i_item_sk = ci.i_item_sk
CROSS JOIN max_global_net_profit
WHERE EXISTS (
    SELECT 1 FROM reason r
    WHERE r.r_reason_desc LIKE 'Customer%'
)
UNION
SELECT
    'Web' AS channel,
    concat(i_brand, ' - ', i_item_desc) AS item_full_desc,
    web_net_profit AS net_profit,
    web_txn_count AS txn_count,
    (web_net_profit / max_global_net_profit.max_profit) * 100 AS profit_pct_of_max,
    CASE
        WHEN REGEXP_LIKE(i_item_desc, '.*[Gg]adget.*') THEN 'Gadget'
        ELSE 'Other'
    END AS item_category_group
FROM web_agg
JOIN common_items ci ON web_agg.i_item_sk = ci.i_item_sk
CROSS JOIN max_global_net_profit
WHERE EXISTS (
    SELECT 1 FROM reason r
    WHERE r.r_reason_desc LIKE 'Customer%'
)
ORDER BY profit_pct_of_max DESC
LIMIT 100
