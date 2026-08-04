/*
Goal: Identify the top‑selling items (by combined store and web sales) that have never been returned, enriched with profit level flags and average store quantity, while demonstrating a wide range of SQL features:
- EXCEPT to subtract items that appear in store_returns
- FULL OUTER JOIN to keep unmatched store‑only and web‑only items
- CASE WHEN to classify profit as HIGH/LOW
- GROUP BY CUBE to produce all‑dimension aggregates for item, category and brand
- LATERAL subquery to compute the average store‑sale quantity per item
- EXISTS subquery to keep only items that participated in a radio promotion
*/
WITH store_agg AS (
    SELECT
        ss.ss_item_sk,
        i.i_category,
        i.i_brand,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY CUBE (ss.ss_item_sk, i.i_category, i.i_brand)
),
web_agg AS (
    SELECT
        ws.ws_item_sk,
        i.i_category,
        i.i_brand,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY CUBE (ws.ws_item_sk, i.i_category, i.i_brand)
),
store_vs_web AS (
    SELECT
        COALESCE(sa.ss_item_sk, wa.ws_item_sk)                     AS item_sk,
        COALESCE(sa.i_category, wa.i_category)                   AS category,
        COALESCE(sa.i_brand, wa.i_brand)                         AS brand,
        sa.total_sales                                            AS store_sales,
        wa.total_sales                                            AS web_sales,
        sa.profit_level                                          AS store_profit_level,
        wa.profit_level                                          AS web_profit_level,
        lt.avg_qty                                                AS avg_store_qty
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa
        ON sa.ss_item_sk = wa.ws_item_sk
        AND sa.i_category = wa.i_category
        AND sa.i_brand = wa.i_brand
    LEFT JOIN LATERAL (
        SELECT AVG(ss_quantity) AS avg_qty
        FROM store_sales ss
        WHERE ss.ss_item_sk = COALESCE(sa.ss_item_sk, wa.ws_item_sk)
    ) lt ON TRUE
)
SELECT
    svw.item_sk,
    svw.category,
    svw.brand,
    svw.store_sales,
    svw.web_sales,
    svw.avg_store_qty
FROM store_vs_web svw
WHERE svw.item_sk IS NOT NULL
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = svw.item_sk
          AND p.p_channel_radio = 'Y'
    )
EXCEPT
SELECT
    i.i_item_sk        AS item_sk,
    i.i_category       AS category,
    i.i_brand          AS brand,
    CAST(0 AS decimal(7,2)) AS store_sales,
    CAST(0 AS decimal(7,2)) AS web_sales,
    CAST(0 AS double)       AS avg_store_qty
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE sr.sr_return_quantity > 0
ORDER BY store_sales DESC
LIMIT 100
