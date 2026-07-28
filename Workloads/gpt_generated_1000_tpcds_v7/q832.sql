WITH filtered_sales AS (
    SELECT cs.cs_call_center_sk,
           cs.cs_item_sk,
           cs.cs_ext_sales_price,
           cs.cs_ext_tax,
           cs.cs_net_profit,
           cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_ext_tax > 50
      AND cs.cs_ext_sales_price BETWEEN 1000 AND 10000
      AND cs.cs_quantity >= 1
),
joined AS (
    SELECT fc.cc_call_center_sk,
           fc.cc_city,
           fc.cc_sq_ft,
           i.i_item_sk,
           i.i_brand,
           i.i_container,
           fs.cs_ext_sales_price,
           fs.cs_ext_tax,
           fs.cs_net_profit,
           CASE WHEN i.i_container = 'Unknown' THEN 'NoContainer' ELSE i.i_container END AS container_flag
    FROM filtered_sales fs
    JOIN call_center fc ON fs.cs_call_center_sk = fc.cc_call_center_sk
    JOIN item i ON fs.cs_item_sk = i.i_item_sk
    WHERE fc.cc_city IN ('Spring Hill', 'Georgetown')
      AND fc.cc_sq_ft > 0
      AND i.i_container <> 'Unknown'
),
agg AS (
    SELECT
        cc_city,
        cc_sq_ft,
        i_brand,
        container_flag,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit
    FROM joined
    GROUP BY cc_city, cc_sq_ft, i_brand, container_flag
)
SELECT
    cc_city,
    cc_sq_ft,
    i_brand,
    container_flag,
    total_sales,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY cc_city ORDER BY total_sales DESC) AS city_sales_rank,
    RANK() OVER (ORDER BY total_sales DESC) AS overall_sales_rank
FROM agg
WHERE total_sales > 5000
ORDER BY total_sales DESC
LIMIT 20
