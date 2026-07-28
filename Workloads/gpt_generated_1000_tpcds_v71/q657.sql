WITH sales AS (
    SELECT
        i.i_manufact,
        i.i_brand,
        i.i_product_name,
        i.i_formulation,
        d.d_month_seq,
        cs.cs_ext_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2020
      AND regexp_like(i.i_manufact, '(?i)bar')
      AND regexp_like(i.i_formulation, '^[0-9]{3,}')
      AND cp.cp_description LIKE '%sale%'
)
SELECT
    i_manufact,
    CONCAT(i_manufact, '-', i_brand) AS manuf_brand,
    SUBSTRING(i_product_name, 1, 5) AS prod_prefix,
    regexp_extract(i_formulation, '(\\d+)', 1) AS first_number,
    d_month_seq,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit
FROM sales
GROUP BY
    i_manufact,
    i_brand,
    i_product_name,
    i_formulation,
    d_month_seq
ORDER BY total_profit DESC
LIMIT 100
