WITH
  union_sales AS (
    SELECT
      cs.cs_order_number               AS order_number,
      cs.cs_ext_sales_price            AS sales,
      cs.cs_net_profit                 AS profit,
      cs.cs_item_sk                    AS item_sk,
      cs.cs_ship_mode_sk               AS ship_mode_sk,
      cs.cs_warehouse_sk               AS warehouse_sk,
      cs.cs_sold_time_sk               AS sold_time_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      ws.ws_item_sk,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      ws.ws_sold_time_sk
    FROM web_sales ws
  )
SELECT
  i1.i_brand                              AS brand,
  sm1.sm_type                             AS ship_type,
  td1.t_hour                              AS hour_of_day,
  MIN(i3.i_category)                     AS category,
  SUM(us.sales)                           AS total_sales,
  SUM(us.profit)                          AS total_profit,
  (SELECT AVG(cs.cs_ext_sales_price)
   FROM catalog_sales cs
   JOIN item i_avg ON cs.cs_item_sk = i_avg.i_item_sk
   WHERE i_avg.i_brand = 'corpbrand #6') AS avg_brand_sales,
  COUNT(*)                                AS transaction_count
FROM union_sales us
JOIN item i1        ON us.item_sk      = i1.i_item_sk          -- join rule 1
JOIN item i3        ON us.item_sk      = i3.i_item_sk          -- same rule, second alias
JOIN ship_mode sm1  ON us.ship_mode_sk = sm1.sm_ship_mode_sk   -- join rule 2
JOIN ship_mode sm2  ON us.ship_mode_sk = sm2.sm_ship_mode_sk   -- same rule, second alias
JOIN warehouse w1   ON us.warehouse_sk = w1.w_warehouse_sk    -- join rule 3
JOIN warehouse w2   ON us.warehouse_sk = w2.w_warehouse_sk    -- same rule, second alias
JOIN time_dim td1   ON us.sold_time_sk = td1.t_time_sk        -- join rule 4
JOIN store_returns sr ON sr.sr_item_sk = i1.i_item_sk        -- join rule 5 (via item)
JOIN item i2        ON sr.sr_item_sk = i2.i_item_sk          -- join rule 5, second alias
JOIN time_dim td2   ON sr.sr_return_time_sk = td2.t_time_sk  -- join rule 6
GROUP BY GROUPING SETS (
  (i1.i_brand, sm1.sm_type, td1.t_hour),
  (i1.i_brand, sm1.sm_type),
  (i1.i_brand),
  (sm1.sm_type),
  ()
)
ORDER BY total_sales DESC
LIMIT 100
