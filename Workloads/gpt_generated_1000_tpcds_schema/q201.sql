WITH filtered_sales AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        i.i_category,
        i.i_item_desc,
        w.w_warehouse_name,
        cp.cp_description,
        regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word_desc
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(i.i_item_desc, '(?i)large')
      AND cp.cp_description LIKE '%Spring%'
)
SELECT
    CONCAT(w_warehouse_name, ' - ', i_category) AS warehouse_category,
    w_warehouse_name,
    i_category,
    first_word_desc,
    SUM(cs_net_profit) AS total_profit,
    SUM(cs_quantity) AS total_quantity,
    COUNT(*) AS sales_transactions,
    ROW_NUMBER() OVER (ORDER BY SUM(cs_net_profit) DESC) AS rn
FROM filtered_sales
GROUP BY
    w_warehouse_name,
    i_category,
    first_word_desc,
    CONCAT(w_warehouse_name, ' - ', i_category)
ORDER BY total_profit DESC
