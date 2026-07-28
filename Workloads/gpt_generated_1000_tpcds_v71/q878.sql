WITH sales_by_source AS (
    -- Catalog sales per item per day
    SELECT
        cs.cs_item_sk AS item_sk,
        i.i_category AS category,
        cs.cs_sold_date_sk AS sold_date_sk,
        SUM(cs.cs_net_paid) AS net_paid,
        CAST('catalog' AS varchar) AS channel
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY cs.cs_item_sk, i.i_category, cs.cs_sold_date_sk
    UNION ALL
    -- Store sales per item per day
    SELECT
        ss.ss_item_sk AS item_sk,
        i.i_category AS category,
        ss.ss_sold_date_sk AS sold_date_sk,
        SUM(ss.ss_net_paid) AS net_paid,
        CAST('store' AS varchar) AS channel
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY ss.ss_item_sk, i.i_category, ss.ss_sold_date_sk
)
SELECT
    sbs.item_sk,
    sbs.category,
    sbs.sold_date_sk,
    SUM(sbs.net_paid) AS total_net_paid,
    COUNT(DISTINCT sbs.channel) AS channels_sold_in
FROM sales_by_source sbs
GROUP BY sbs.item_sk, sbs.category, sbs.sold_date_sk
HAVING SUM(sbs.net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
