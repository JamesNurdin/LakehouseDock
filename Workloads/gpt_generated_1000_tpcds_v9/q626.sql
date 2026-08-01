WITH base_sales AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cp.cp_start_date_sk,
        cp.cp_end_date_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_ship_cost,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt
    FROM catalog_page cp
    JOIN catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department IN ('Books', 'Electronics', 'Clothing')
      AND cp.cp_catalog_page_number BETWEEN 2 AND 21
      AND cp.cp_catalog_number BETWEEN 4 AND 16
      AND cp.cp_start_date_sk >= 2450900
      AND cp.cp_end_date_sk <= 2451300
      AND cs.cs_ext_ship_cost > 100
      AND cs.cs_net_profit > 0
      AND cs.cs_sales_price < 100
      AND cs.cs_quantity > 0
)

SELECT
    cp_sk,
    cp_catalog_page_id,
    cp_department,
    cp_catalog_number,
    cp_catalog_page_number,
    metric_name,
    SUM(metric_value) AS total_metric,
    MAX(rank_by_metric) AS max_rank
FROM (
    SELECT
        bs.cp_catalog_page_sk AS cp_sk,
        bs.cp_catalog_page_id,
        bs.cp_department,
        bs.cp_catalog_number,
        bs.cp_catalog_page_number,
        bs.cs_sold_date_sk,
        metric_name,
        metric_value,
        ROW_NUMBER() OVER (PARTITION BY bs.cp_catalog_page_sk ORDER BY metric_value DESC) AS rank_by_metric
    FROM base_sales bs
    CROSS JOIN UNNEST(
        ARRAY['quantity', 'sales_price'],
        ARRAY[CAST(bs.cs_quantity AS DOUBLE), CAST(bs.cs_sales_price AS DOUBLE)]
    ) AS u(metric_name, metric_value)
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_catalog_page_sk = bs.cp_catalog_page_sk
          AND cs2.cs_ext_discount_amt > 5000
    )
) q
GROUP BY GROUPING SETS (
    (cp_sk, cp_catalog_page_id, cp_department, cp_catalog_number, cp_catalog_page_number, metric_name),
    (cp_department, cp_catalog_number, cp_catalog_page_number, metric_name),
    (cp_department, cp_catalog_number, metric_name),
    (cp_department, metric_name),
    (metric_name)
)
ORDER BY total_metric DESC, max_rank
LIMIT 100
