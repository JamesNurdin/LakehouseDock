WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_ext_tax) AS total_ext_tax
    FROM catalog_sales cs
    WHERE cs.cs_ext_tax > 10
      AND cs.cs_quantity > 5
      AND cs.cs_net_paid_inc_tax BETWEEN 1000 AND 5000
      AND cs.cs_wholesale_cost < 50
      AND cs.cs_list_price > 20
      AND cs.cs_coupon_amt >= 0
    GROUP BY cs.cs_item_sk
),
item_set_high_cost AS (
    SELECT i.i_item_sk FROM item i WHERE i.i_wholesale_cost > 40
),
item_set_class AS (
    SELECT i.i_item_sk FROM item i WHERE i.i_class IN ('maternity', 'scanners')
),
common_items AS (
    SELECT i_item_sk FROM item_set_high_cost
    INTERSECT
    SELECT i_item_sk FROM item_set_class
)
SELECT
    i.i_category,
    i.i_class,
    lvl.level,
    SUM(sa.total_quantity) AS sum_quantity,
    SUM(sa.total_net_paid) AS sum_net_paid,
    AVG(sa.avg_sales_price) AS avg_price,
    MAX(l.max_net_paid) AS max_item_net_paid,
    RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(sa.total_net_paid) DESC) AS category_rank,
    CASE
        WHEN SUM(sa.total_net_paid) > 20000 THEN 'High'
        WHEN SUM(sa.total_net_paid) > 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_bucket
FROM item i
JOIN sales_agg sa ON sa.cs_item_sk = i.i_item_sk
JOIN common_items ci ON ci.i_item_sk = i.i_item_sk
CROSS JOIN LATERAL (
    SELECT MAX(cs.cs_net_paid_inc_tax) AS max_net_paid
    FROM catalog_sales cs
    WHERE cs.cs_item_sk = i.i_item_sk
      AND cs.cs_ext_tax > 20
) l
CROSS JOIN (VALUES (1, 'Low'), (2, 'Medium'), (3, 'High')) AS lvl(rank, level)
WHERE i.i_container = 'Unknown'
  AND i.i_units = 'Dozen'
  AND i.i_brand_id >= 0
  AND i.i_manufact_id IS NOT NULL
GROUP BY GROUPING SETS (
    (i.i_category, i.i_class, lvl.level),
    (i.i_category, lvl.level),
    (lvl.level)
)
ORDER BY i.i_category ASC, sum_net_paid DESC
OFFSET 0 ROWS
LIMIT 100
