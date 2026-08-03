WITH sales_agg AS (
   SELECT
       cs_item_sk,
       cs_ship_mode_sk,
       SUM(cs_net_paid_inc_tax) AS sum_net_paid_inc_tax,
       SUM(cs_net_profit) AS sum_net_profit,
       COUNT(*) AS sales_cnt
   FROM catalog_sales TABLESAMPLE BERNOULLI (10)
   WHERE cs_net_paid_inc_tax > 500
     AND cs_quantity >= 1
   GROUP BY cs_item_sk, cs_ship_mode_sk
),
joined AS (
   SELECT
       sa.cs_item_sk,
       sa.cs_ship_mode_sk,
       sa.sum_net_paid_inc_tax,
       sa.sum_net_profit,
       sa.sales_cnt,
       cr.cr_order_number,
       cr.cr_return_quantity,
       cr.cr_reversed_charge,
       i.i_category,
       i.i_current_price,
       sm.sm_type,
       ROW_NUMBER() OVER (PARTITION BY sa.cs_item_sk ORDER BY sa.sum_net_paid_inc_tax DESC) AS rn
   FROM sales_agg sa
   JOIN catalog_returns cr
       ON sa.cs_item_sk = cr.cr_item_sk
   JOIN item i
       ON sa.cs_item_sk = i.i_item_sk
   JOIN ship_mode sm
       ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE cr.cr_reversed_charge < 100
     AND i.i_current_price BETWEEN 20 AND 1000
     AND sm.sm_type = 'AIR'
)
SELECT
    i_category,
    AVG(sum_net_profit) AS avg_profit_per_item,
    SUM(sum_net_paid_inc_tax) AS total_net_paid,
    COUNT(DISTINCT cs_item_sk) AS distinct_items,
    MAX(rn) AS max_rank
FROM joined
WHERE rn <= 10
GROUP BY i_category
HAVING COUNT(DISTINCT cs_item_sk) > 5
ORDER BY avg_profit_per_item DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
