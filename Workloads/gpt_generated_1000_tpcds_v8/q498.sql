-- Goal: Compute average net profit and order statistics per call center and item category for high‑value promotions, applying several demographic and sales filters, and then enrich the result with cross‑joined year/bucket rows, array expansion, intersected item sets, and correlated aggregates.
WITH filtered_sales AS (
   SELECT
       cs.cs_order_number,
       cs.cs_call_center_sk,
       cs.cs_item_sk,
       cs.cs_promo_sk,
       cs.cs_bill_cdemo_sk,
       cs.cs_quantity,
       cs.cs_ext_sales_price,
       cs.cs_net_profit,
       cc.cc_name,
       i.i_category,
       p.p_response_target,
       p.p_channel_demo,
       cd.cd_gender,
       cd.cd_dep_count
   FROM catalog_sales cs
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
     AND cc.cc_rec_end_date   <= DATE '2005-12-31'
     AND p.p_response_target  >= 5
     AND p.p_channel_demo     = 'N'
     AND cd.cd_dep_count      BETWEEN 2 AND 5
     AND cs.cs_ext_sales_price > 1000
     AND cs.cs_quantity        >= 2
),

sales_agg AS (
   SELECT
       fs.cs_call_center_sk,
       fs.cs_item_sk,
       fs.cc_name,
       fs.i_category,
       SUM(fs.cs_net_profit)              AS total_profit,
       COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
       AVG(fs.cs_quantity)                AS avg_quantity
   FROM filtered_sales fs
   GROUP BY fs.cs_call_center_sk, fs.cs_item_sk, fs.cc_name, fs.i_category
),

high_profit_set1 AS (
   SELECT cs_item_sk
   FROM catalog_sales
   WHERE cs_net_profit > 5000
   GROUP BY cs_item_sk
),

high_profit_set2 AS (
   SELECT cs_item_sk
   FROM catalog_sales
   WHERE cs_ext_sales_price > 20000
   GROUP BY cs_item_sk
),

intersect_items AS (
   SELECT cs_item_sk FROM high_profit_set1
   INTERSECT
   SELECT cs_item_sk FROM high_profit_set2
),

year_vals AS (
   SELECT 2020 AS yr UNION ALL SELECT 2021 UNION ALL SELECT 2022
),

discount_bucket AS (
   SELECT 0 AS bucket UNION ALL SELECT 10 UNION ALL SELECT 20
),

cross_joined AS (
   SELECT y.yr, d.bucket
   FROM year_vals y CROSS JOIN discount_bucket d
),

final AS (
   SELECT
       sa.cs_call_center_sk,
       sa.cs_item_sk,
       sa.cc_name,
       sa.i_category,
       sa.total_profit,
       sa.distinct_orders,
       sa.avg_quantity,
       -- correlated scalar subquery: total sales price for the same call center across all catalog_sales
       (SELECT SUM(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = sa.cs_call_center_sk) AS call_center_sales,
       -- unnest an array containing profit and avg quantity per group
       unnested.profit,
       unnested.qty
   FROM sales_agg sa
   LEFT JOIN LATERAL (
       SELECT profit, qty
       FROM UNNEST(ARRAY[
           ROW(sa.total_profit, sa.avg_quantity)
       ]) AS t(profit, qty)
   ) AS unnested ON TRUE
   WHERE sa.cs_item_sk IN (SELECT cs_item_sk FROM intersect_items)
     AND EXISTS (
         SELECT 1
         FROM catalog_sales cs_sub
         WHERE cs_sub.cs_call_center_sk = sa.cs_call_center_sk
           AND cs_sub.cs_ship_cdemo_sk = (
               SELECT cd_demo_sk
               FROM customer_demographics
               WHERE cd_gender = 'F'
               LIMIT 1
           )
     )
)

SELECT DISTINCT
    f.cc_name,
    f.i_category,
    f.total_profit,
    f.distinct_orders,
    f.avg_quantity,
    f.call_center_sales,
    f.profit,
    f.qty,
    cj.yr,
    cj.bucket
FROM final f
CROSS JOIN cross_joined cj
WHERE f.total_profit > 10000
  AND f.distinct_orders >= 5
  AND f.call_center_sales IS NOT NULL
ORDER BY f.total_profit DESC, f.cc_name
LIMIT 100
