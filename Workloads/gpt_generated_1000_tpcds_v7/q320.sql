WITH item_sales AS (
    SELECT
        cs.cs_net_profit,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        sm.sm_type,
        w.w_city,
        cc.cc_name
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]')
      AND cc.cc_name LIKE '%Center%'
)
SELECT
    i_category,
    i_class,
    sm_type,
    w_city,
    concat(i_brand, ' ', i_product_name) AS product_full_name,
    regexp_extract(i_item_desc, '^(\\w+)', 1) AS first_word,
    sum(cs_net_profit) AS total_net_profit,
    count(*) AS sales_transactions
FROM item_sales
GROUP BY
    i_category,
    i_class,
    sm_type,
    w_city,
    concat(i_brand, ' ', i_product_name),
    regexp_extract(i_item_desc, '^(\\w+)', 1)
ORDER BY total_net_profit DESC
LIMIT 100
