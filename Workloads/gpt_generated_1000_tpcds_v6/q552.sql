WITH filtered_items AS (
    SELECT i_item_sk, i_brand, i_formulation
    FROM tpcds.item
    WHERE i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
)
SELECT brand, total_profit
FROM (
    SELECT fi.i_brand AS brand,
           SUM(ws.ws_net_profit) AS total_profit
    FROM filtered_items fi
    JOIN tpcds.web_sales ws ON ws.ws_item_sk = fi.i_item_sk
    WHERE fi.i_formulation LIKE '%moccasin%'
    GROUP BY fi.i_brand
    HAVING SUM(ws.ws_net_profit) > (
        SELECT AVG(ws2.ws_net_profit)
        FROM tpcds.web_sales ws2
    )
    UNION ALL
    SELECT fi.i_brand AS brand,
           SUM(ws.ws_net_profit) AS total_profit
    FROM filtered_items fi
    JOIN tpcds.web_sales ws ON ws.ws_item_sk = fi.i_item_sk
    WHERE fi.i_formulation LIKE '%steel%'
    GROUP BY fi.i_brand
    HAVING SUM(ws.ws_net_profit) > (
        SELECT AVG(ws2.ws_net_profit)
        FROM tpcds.web_sales ws2
    )
) AS combined
ORDER BY total_profit DESC
LIMIT 100
