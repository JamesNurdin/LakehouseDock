WITH item_desc_filtered AS (
    SELECT cs.cs_sold_time_sk,
           cs.cs_bill_cdemo_sk,
           cs.cs_item_sk,
           cs.cs_net_profit,
           cs.cs_quantity,
           i.i_brand,
           i.i_category,
           i.i_item_id,
           i.i_item_desc,
           i.i_product_name,
           i.i_rec_start_date,
           cd.cd_marital_status
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
      AND i.i_brand LIKE 'Brand%'
      AND cd.cd_marital_status = 'M'
      AND i.i_rec_start_date >= DATE '1998-01-01'
      AND i.i_rec_start_date < DATE '1999-01-01'
),
avg_profit AS (
    SELECT avg(cs_net_profit) AS avg_net_profit
    FROM catalog_sales
)
SELECT
    i_brand,
    i_category,
    concat(i_brand, ' - ', i_category) AS brand_category,
    substring(i_product_name, 1, 15) AS short_product_name,
    regexp_extract(i_item_id, '([0-9]+)') AS item_id_number,
    CASE
        WHEN sum(cs_net_profit) > 20000 THEN 'Very High'
        WHEN sum(cs_net_profit) > 10000 THEN 'High'
        WHEN sum(cs_net_profit) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_level,
    sum(cs_net_profit) AS total_net_profit,
    (SELECT avg_net_profit FROM avg_profit) AS overall_avg_net_profit,
    CASE WHEN sum(cs_net_profit) > (SELECT avg_net_profit FROM avg_profit) THEN 1 ELSE 0 END AS above_avg_flag
FROM item_desc_filtered
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = item_desc_filtered.cs_item_sk
      AND cs2.cs_quantity > 5
)
GROUP BY i_brand, i_category, i_product_name, i_item_id
HAVING sum(cs_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 100
