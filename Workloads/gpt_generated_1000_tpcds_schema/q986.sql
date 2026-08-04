WITH
  store_agg AS (
    SELECT
      ss_cdemo_sk,
      SUM(ss_net_paid) AS sum_ss_net_paid,
      COUNT(DISTINCT ss_item_sk) AS distinct_items_sold,
      AVG(ss_sales_price) AS avg_sales_price
    FROM store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_cdemo_sk
  ),
  catalog_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 0
  ),
  joined_base AS (
    SELECT
      cd.cd_gender,
      cd.cd_marital_status,
      lc.spend_category,
      SUM(cs.cs_net_profit)                         AS total_catalog_profit,
      SUM(ss_agg.sum_ss_net_paid)                  AS total_store_paid,
      COUNT(DISTINCT cs.cs_order_number)           AS distinct_orders,
      COUNT(DISTINCT wr.wr_return_quantity)       AS distinct_return_qty
    FROM store_agg ss_agg
    JOIN customer_demographics cd
      ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_sample cs
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr
      ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
     AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2453665
    CROSS JOIN LATERAL (
      SELECT CASE
               WHEN ss_agg.sum_ss_net_paid / NULLIF(ss_agg.distinct_items_sold, 0) > 200
               THEN 'HIGH'
               ELSE 'LOW'
             END AS spend_category
    ) lc
    WHERE cd.cd_dep_count >= 2
      AND cs.cs_list_price > 30
      AND ss_agg.sum_ss_net_paid > 1000
      AND EXISTS (
            SELECT 1
            FROM catalog_sales cs2
            WHERE cs2.cs_promo_sk = cs.cs_promo_sk
              AND cs2.cs_net_profit > 0
          )
    GROUP BY CUBE(cd.cd_gender, cd.cd_marital_status, lc.spend_category)
    HAVING SUM(cs.cs_net_profit) > 0
  )
SELECT
  *,
  ROW_NUMBER() OVER (ORDER BY total_store_paid DESC) AS rn
FROM joined_base
