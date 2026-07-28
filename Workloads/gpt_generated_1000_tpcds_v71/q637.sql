WITH inventory_agg AS (
   SELECT inv_item_sk,
          SUM(inv_quantity_on_hand) AS total_qty_on_hand
   FROM inventory
   GROUP BY inv_item_sk
),
catalog_data AS (
   SELECT cs.cs_order_number,
          cs.cs_sold_date_sk,
          cs.cs_net_paid,
          cs.cs_net_profit,
          cs.cs_quantity,
          cs.cs_item_sk AS i_item_sk,
          i.i_item_id,
          i.i_product_name,
          i.i_current_price,
          cc.cc_name,
          cp.cp_type,
          sm.sm_type,
          p.p_promo_name,
          ia.total_qty_on_hand,
          cr.cr_return_quantity,
          cr.cr_return_amount
   FROM catalog_sales cs
   JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
   JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN catalog_returns cr  ON cr.cr_order_number = cs.cs_order_number
   LEFT JOIN inventory_agg ia     ON ia.inv_item_sk = i.i_item_sk
   WHERE cc.cc_gmt_offset BETWEEN -5 AND 5
     AND cp.cp_type IN ('quarterly', 'monthly')
     AND p.p_channel_event = 'N'
     AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450500
     AND sm.sm_type <> 'MEDIUM'
     AND i.i_current_price > 0
)
SELECT *
FROM (
   SELECT
       cd.cs_sold_date_sk,
       cd.cs_order_number,
       cd.i_item_id,
       cd.i_product_name,
       cd.cc_name,
       cd.cp_type,
       cd.sm_type,
       cd.p_promo_name,
       cd.total_qty_on_hand,
       cd.cs_net_profit,
       RANK() OVER (PARTITION BY cd.i_item_id ORDER BY cd.cs_net_profit DESC) AS profit_rank,
       CASE
           WHEN cd.cs_net_profit > 0 THEN 'PROFITABLE'
           WHEN cd.cs_net_profit = 0 THEN 'BREAK_EVEN'
           ELSE 'LOSS'
       END AS profit_category,
       (
           SELECT AVG(cs2.cs_net_profit)
           FROM catalog_sales cs2
           WHERE cs2.cs_item_sk = cd.i_item_sk
       ) AS avg_item_profit
   FROM catalog_data cd
   WHERE cd.cr_return_quantity IS NULL OR cd.cr_return_quantity = 0
) UNION ALL
SELECT
   ss.ss_sold_date_sk,
   ss.ss_ticket_number            AS cs_order_number,
   i.i_item_id,
   i.i_product_name,
   NULL                           AS cc_name,
   NULL                           AS cp_type,
   NULL                           AS sm_type,
   p.p_promo_name,
   ia.total_qty_on_hand,
   ss.ss_net_profit,
   ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ss.ss_net_profit DESC) AS profit_rank,
   CASE
       WHEN ss.ss_net_profit > 0 THEN 'PROFITABLE'
       WHEN ss.ss_net_profit = 0 THEN 'BREAK_EVEN'
       ELSE 'LOSS'
   END AS profit_category,
   (
       SELECT AVG(ss2.ss_net_profit)
       FROM store_sales ss2
       WHERE ss2.ss_item_sk = i.i_item_sk
   ) AS avg_item_profit
FROM store_sales ss
JOIN store s               ON ss.ss_store_sk = s.s_store_sk
JOIN item i                ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
JOIN inventory_agg ia      ON ia.inv_item_sk = i.i_item_sk
WHERE s.s_state = 'GA'
  AND p.p_channel_email = 'N'
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450500
  AND i.i_current_price BETWEEN 10 AND 1000
  AND ss.ss_quantity > 0
  AND ss.ss_net_paid > 0
LIMIT 100
