WITH item_totals AS (
    SELECT
        cs_item_sk,
        SUM(cs_net_paid_inc_ship_tax) AS item_total_net_paid,
        SUM(cs_quantity) AS item_total_qty
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship_tax > 500
    GROUP BY cs_item_sk
)
SELECT
    cs.cs_catalog_page_sk,
    COUNT(*) AS sales_cnt,
    SUM(cs.cs_net_paid_inc_ship_tax) AS page_total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_net_paid_inc_ship_tax) / SUM(it.item_total_net_paid) AS page_to_item_net_ratio,
    RANK() OVER (ORDER BY SUM(cs.cs_net_paid_inc_ship_tax) DESC) AS revenue_rank
FROM catalog_sales cs
JOIN item_totals it
    ON cs.cs_item_sk = it.cs_item_sk
WHERE cs.cs_sold_time_sk BETWEEN 40000 AND 80000
  AND cs.cs_ext_ship_cost < 1500
GROUP BY cs.cs_catalog_page_sk
HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 10000
ORDER BY revenue_rank
LIMIT 20
