WITH sales_union AS (
   SELECT
        i.i_item_sk,
        i.i_product_name,
        w.w_warehouse_name,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        'web' AS channel,
        regexp_extract(i.i_product_name, '(\\d{3,})', 1) AS product_number_extracted,
        concat(i.i_product_name, ' - ', w.w_warehouse_name) AS product_warehouse_concat,
        substring(i.i_product_name, 1, 5) AS product_name_prefix
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE regexp_like(i.i_product_name, '[A-Z]{2}')
     AND i.i_product_name LIKE '%CO%'
   UNION ALL
   SELECT
        i.i_item_sk,
        i.i_product_name,
        w.w_warehouse_name,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel,
        regexp_extract(i.i_product_name, '(\\d{3,})', 1) AS product_number_extracted,
        concat(i.i_product_name, ' - ', w.w_warehouse_name) AS product_warehouse_concat,
        substring(i.i_product_name, 1, 5) AS product_name_prefix
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE regexp_like(i.i_product_name, '[A-Z]{2}')
     AND i.i_product_name LIKE '%CO%'
)
SELECT
    i_item_sk,
    w_warehouse_name,
    channel,
    MAX(product_number_extracted) AS product_number_extracted,
    MAX(product_warehouse_concat) AS product_warehouse_concat,
    MAX(product_name_prefix) AS product_name_prefix,
    SUM(quantity) AS total_quantity,
    SUM(net_profit) AS total_net_profit
FROM sales_union
GROUP BY GROUPING SETS (
    (i_item_sk, w_warehouse_name, channel),
    (i_item_sk, w_warehouse_name),
    (i_item_sk, channel),
    (i_item_sk),
    ()
)
HAVING SUM(net_profit) > (SELECT AVG(net_profit) FROM sales_union)
ORDER BY total_net_profit DESC
LIMIT 100
