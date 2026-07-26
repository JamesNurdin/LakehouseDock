WITH item_perf AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_net_paid) AS total_paid,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        CASE
            WHEN SUM(cs.cs_net_paid) = 0 THEN 0
            ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid)
        END AS profit_margin
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category
)
SELECT
    i_item_id,
    i_product_name,
    i_brand,
    i_category,
    total_quantity,
    total_profit,
    total_paid,
    profit_margin,
    DENSE_RANK() OVER (ORDER BY profit_margin DESC) AS margin_rank
FROM item_perf
WHERE total_quantity > 0
ORDER BY margin_rank
LIMIT 10
