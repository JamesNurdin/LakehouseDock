WITH
  sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  sales_items AS (
    SELECT DISTINCT cs_item_sk
    FROM sampled_sales
  ),
  returns_items AS (
    SELECT DISTINCT sr_item_sk
    FROM store_returns
  ),
  diff_items AS (
    SELECT cs_item_sk AS item_sk
    FROM sales_items
    EXCEPT
    SELECT sr_item_sk
    FROM returns_items
  ),
  joined AS (
    SELECT
      s.s_store_id,
      w.w_warehouse_name,
      cp.cp_catalog_page_number,
      td_sales.t_hour,
      cs.cs_net_profit,
      sr.sr_net_loss,
      l.avg_sales_price
    FROM sampled_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i_sales
      ON cs.cs_item_sk = i_sales.i_item_sk
    JOIN time_dim td_sales
      ON cs.cs_sold_time_sk = td_sales.t_time_sk
    -- second aliases of catalog_page and warehouse to increase join count
    JOIN catalog_page cp2
      ON cs.cs_catalog_page_sk = cp2.cp_catalog_page_sk
    JOIN warehouse w2
      ON cs.cs_warehouse_sk = w2.w_warehouse_sk
    JOIN diff_items di
      ON i_sales.i_item_sk = di.item_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = di.item_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN item i_returns
      ON sr.sr_item_sk = i_returns.i_item_sk
    JOIN time_dim td_returns
      ON sr.sr_return_time_sk = td_returns.t_time_sk
    LEFT JOIN LATERAL (
      SELECT avg(cs2.cs_sales_price) AS avg_sales_price
      FROM catalog_sales cs2
      WHERE cs2.cs_item_sk = i_sales.i_item_sk
    ) l ON TRUE
    WHERE cp.cp_catalog_page_number BETWEEN 10 AND 20
  )
SELECT
  s_store_id,
  w_warehouse_name,
  cp_catalog_page_number,
  t_hour,
  sum(cs_net_profit) AS total_net_profit,
  sum(sr_net_loss) AS total_return_loss,
  avg(avg_sales_price) AS avg_item_sales_price
FROM joined
GROUP BY
  s_store_id,
  w_warehouse_name,
  cp_catalog_page_number,
  t_hour
ORDER BY total_net_profit DESC
LIMIT 100
