WITH sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        cp.cp_description,
        d.d_date,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_description, '(?i)discount|sale')
      AND i.i_product_name LIKE '%Co%'
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
agg AS (
    SELECT
        i_item_id,
        i_product_name,
        sum(cs_quantity) AS total_quantity,
        sum(cs_net_profit) AS total_profit,
        regexp_extract(i_product_name, '^([^ ]+)', 1) AS first_word
    FROM sales
    GROUP BY i_item_id, i_product_name
)
SELECT
    i_item_id,
    first_word,
    total_quantity,
    total_profit,
    concat(first_word, ' - ', i_item_id) AS label
FROM agg
WHERE total_profit > 10000
ORDER BY total_profit DESC
LIMIT 100
