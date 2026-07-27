WITH sales_data AS (
    SELECT
        cs.cs_net_profit,
        w.w_city,
        w.w_state,
        i.i_product_name,
        cp.cp_description
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2002
      AND cp.cp_description LIKE '%sale%'
      AND regexp_like(i.i_product_name, '^.*[0-9]{2}.*$')
)
SELECT
    CONCAT(s.w_city, ', ', s.w_state) AS location,
    regexp_extract(s.i_product_name, '^([^ ]+)', 1) AS first_word,
    SUM(s.cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count
FROM sales_data s
GROUP BY
    CONCAT(s.w_city, ', ', s.w_state),
    regexp_extract(s.i_product_name, '^([^ ]+)', 1)
ORDER BY total_net_profit DESC
