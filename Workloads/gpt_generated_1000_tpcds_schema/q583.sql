WITH sampled_sales AS (
   SELECT *
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
),
filtered_sales AS (
   SELECT ss1.*
   FROM sampled_sales ss1
   WHERE ss1.ss_wholesale_cost > 20
     AND ss1.ss_list_price BETWEEN 30 AND 200
     AND ss1.ss_quantity >= 2
     AND ss1.ss_promo_sk IN (754, 1167, 370)
     AND ss1.ss_net_paid > 0
),
hd_filtered AS (
   SELECT *
   FROM household_demographics
   WHERE hd_vehicle_count >= 1
     AND hd_dep_count <= 4
     AND hd_buy_potential LIKE '1001-5000'
     AND hd_buy_potential <> 'Unknown'
),
item_excluded AS (
   SELECT ss_item_sk
   FROM store_sales
   WHERE ss_quantity > 10
   EXCEPT
   SELECT ss_item_sk
   FROM store_sales
   WHERE ss_quantity < 3
),
agg_sales AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_store_sk,
       hd.hd_buy_potential,
       SUM(ss.ss_net_profit) AS total_profit
   FROM filtered_sales ss
   JOIN hd_filtered hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE ss.ss_item_sk NOT IN (SELECT ss_item_sk FROM item_excluded)
   GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk, hd.hd_buy_potential
   HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT
   a.ss_sold_date_sk,
   a.ss_store_sk,
   a.hd_buy_potential,
   a.total_profit,
   RANK() OVER (PARTITION BY a.hd_buy_potential ORDER BY a.total_profit DESC) AS profit_rank_in_potential,
   (SELECT COUNT(*)
      FROM store_sales s2
      WHERE s2.ss_store_sk = a.ss_store_sk
        AND s2.ss_net_profit > a.total_profit) AS higher_profit_store_count
FROM agg_sales a
ORDER BY a.total_profit DESC
LIMIT 100
