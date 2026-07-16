WITH combined_sales AS (
    SELECT
        d.d_year,
        i.i_category,
        'store' AS channel,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS ext_discount_amt,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        i.i_category,
        'catalog' AS channel,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS ext_discount_amt,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        i.i_category,
        'web' AS channel,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS ext_discount_amt,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
)
SELECT
    d_year,
    i_category,
    SUM(CASE WHEN channel = 'store' THEN net_profit END) AS store_net_profit,
    SUM(CASE WHEN channel = 'catalog' THEN net_profit END) AS catalog_net_profit,
    SUM(CASE WHEN channel = 'web' THEN net_profit END) AS web_net_profit,
    AVG(CASE WHEN channel = 'store' THEN ext_discount_amt END) AS store_avg_discount,
    AVG(CASE WHEN channel = 'catalog' THEN ext_discount_amt END) AS catalog_avg_discount,
    AVG(CASE WHEN channel = 'web' THEN ext_discount_amt END) AS web_avg_discount,
    SUM(CASE WHEN channel = 'store' THEN quantity END) AS store_quantity,
    SUM(CASE WHEN channel = 'catalog' THEN quantity END) AS catalog_quantity,
    SUM(CASE WHEN channel = 'web' THEN quantity END) AS web_quantity
FROM combined_sales
GROUP BY d_year, i_category
ORDER BY d_year, i_category
