WITH filtered_sales AS (
    SELECT
        cs.cs_item_sk        AS item_sk,
        cs.cs_warehouse_sk   AS warehouse_sk,
        cs.cs_net_profit     AS net_profit,
        'catalog'            AS source
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cd.cd_education_status LIKE 'Advanced%'
      AND regexp_like(i.i_item_desc, '(?i)premium')
),
web_filtered AS (
    SELECT
        ws.ws_item_sk        AS item_sk,
        ws.ws_warehouse_sk   AS warehouse_sk,
        ws.ws_net_profit     AS net_profit,
        'web'                AS source
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE cd.cd_education_status LIKE 'Advanced%'
      AND regexp_like(i.i_item_desc, '(?i)premium')
)
SELECT
    i.i_brand,
    w.w_state,
    regexp_extract(i.i_item_id, '\\d+', 0) AS item_numeric_code,
    SUM(s.net_profit)                               AS total_net_profit,
    COUNT(*) FILTER (WHERE s.source = 'catalog')    AS catalog_sales_cnt,
    COUNT(*) FILTER (WHERE s.source = 'web')        AS web_sales_cnt
FROM (
    SELECT * FROM filtered_sales
    UNION ALL
    SELECT * FROM web_filtered
) s
JOIN item i
    ON s.item_sk = i.i_item_sk
JOIN warehouse w
    ON s.warehouse_sk = w.w_warehouse_sk
GROUP BY
    i.i_brand,
    w.w_state,
    regexp_extract(i.i_item_id, '\\d+', 0)
HAVING SUM(s.net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 10
