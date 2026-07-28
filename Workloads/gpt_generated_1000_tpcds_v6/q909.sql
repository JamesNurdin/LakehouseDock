WITH store_agg AS (
    SELECT
        'store' AS channel,
        d.d_year,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_store_sk) AS distinct_entity_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1 FROM item i2
          WHERE i2.i_item_sk = ss.ss_item_sk
            AND i2.i_current_price > 100
      )
    GROUP BY ROLLUP (d.d_year, i.i_category)
),
web_agg AS (
    SELECT
        'web' AS channel,
        d.d_year,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_warehouse_sk) AS distinct_entity_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 100
    GROUP BY ROLLUP (d.d_year, i.i_category)
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    channel,
    d_year,
    i_category,
    SUM(total_net_profit) AS total_net_profit,
    SUM(distinct_entity_cnt) AS distinct_entity_cnt
FROM combined
GROUP BY ROLLUP (channel, d_year, i_category)
ORDER BY channel, d_year, i_category
LIMIT 100
