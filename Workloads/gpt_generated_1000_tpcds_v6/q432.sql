WITH
  sales_agg AS (
    SELECT
      i_cs.i_item_sk,
      i_cs.i_brand,
      i_cs.i_category,
      SUM(cs.cs_ext_sales_price) AS cat_sales,
      SUM(cs.cs_net_profit) AS cat_profit
    FROM catalog_sales cs
    JOIN item i_cs ON cs.cs_item_sk = i_cs.i_item_sk
    JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
    WHERE td_cs.t_hour BETWEEN 9 AND 17
    GROUP BY i_cs.i_item_sk, i_cs.i_brand, i_cs.i_category
  ),
  store_agg AS (
    SELECT
      i_ss.i_item_sk,
      i_ss.i_brand,
      i_ss.i_category,
      SUM(ss.ss_ext_sales_price) AS store_sales,
      SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
    WHERE td_ss.t_hour BETWEEN 9 AND 17
    GROUP BY i_ss.i_item_sk, i_ss.i_brand, i_ss.i_category
  ),
  returns_agg AS (
    SELECT
      wr.wr_item_sk,
      SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    JOIN time_dim td_ret ON wr.wr_returned_time_sk = td_ret.t_time_sk
    WHERE td_ret.t_hour BETWEEN 9 AND 17
    GROUP BY wr.wr_item_sk
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_brand,
  i.i_category,
  COALESCE(sa.cat_sales, 0) + COALESCE(sta.store_sales, 0) AS total_sales,
  COALESCE(sa.cat_profit, 0) + COALESCE(sta.store_profit, 0) AS total_profit,
  inv.inv_quantity_on_hand,
  ra.total_return_amt
FROM item i
JOIN sales_agg sa ON i.i_item_sk = sa.i_item_sk
JOIN store_agg sta ON i.i_item_sk = sta.i_item_sk
LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN returns_agg ra ON i.i_item_sk = ra.wr_item_sk
WHERE i.i_brand = 'importoamalg #1'
  AND EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    JOIN call_center cc ON cs2.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs2.cs_item_sk = i.i_item_sk
  )
ORDER BY total_sales DESC
LIMIT 100
