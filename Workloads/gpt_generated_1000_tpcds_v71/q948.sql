WITH sales_item AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_ext_tax,
        cs.cs_quantity,
        i.i_brand,
        i.i_brand_id,
        i.i_item_desc,
        i.i_size,
        i.i_formulation,
        i.i_container,
        regexp_extract(i.i_formulation, '([0-9]{6,})') AS numeric_code
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_size LIKE '%large%'
      AND regexp_like(i.i_formulation, '[0-9]{6,}')
)
SELECT
    si.i_brand,
    si.numeric_code,
    CONCAT(si.i_brand, '_', si.numeric_code) AS brand_code,
    COUNT(DISTINCT si.cs_item_sk) AS distinct_items_sold,
    SUM(si.cs_net_profit) AS total_net_profit,
    AVG(si.cs_ext_tax) AS avg_ext_tax,
    CASE
        WHEN SUM(si.cs_net_profit) > 10000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS profit_category
FROM sales_item si
GROUP BY
    si.i_brand,
    si.numeric_code
ORDER BY
    profit_category DESC,
    total_net_profit DESC
LIMIT 100
