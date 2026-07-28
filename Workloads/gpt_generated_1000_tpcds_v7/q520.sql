WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cp.cp_description,
        i.i_formulation,
        i.i_product_name,
        i.i_brand,
        i.i_units
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2021
      AND regexp_like(i.i_formulation, '[0-9]+[a-z]+[0-9]*')
      AND lower(cp.cp_description) LIKE '%national%'
),
filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        d.d_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
      AND cr.cr_return_amount > 0
)
SELECT
    i.i_item_sk,
    concat(i.i_brand, ' ', i.i_product_name) AS full_product_name,
    substr(i.i_formulation, 1, 5) AS formulation_prefix,
    sum(fs.cs_ext_sales_price) AS total_sales,
    sum(fs.cs_net_profit) AS total_profit,
    sum(fr.cr_return_amount) AS total_return_amount,
    count(DISTINCT fs.cs_order_number) AS distinct_orders,
    sum(fr.cr_return_quantity) AS total_return_qty,
    (sum(fs.cs_net_profit) / nullif(sum(fs.cs_ext_sales_price), 0)) * 100 AS profit_margin_percent
FROM filtered_sales fs
JOIN item i ON fs.cs_item_sk = i.i_item_sk
LEFT JOIN filtered_returns fr
    ON fs.cs_order_number = fr.cr_order_number
   AND fs.cs_item_sk = fr.cr_item_sk
GROUP BY
    i.i_item_sk,
    i.i_brand,
    i.i_product_name,
    i.i_formulation
ORDER BY total_profit DESC
LIMIT 100
