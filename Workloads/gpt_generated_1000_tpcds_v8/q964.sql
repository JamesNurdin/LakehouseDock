WITH promo_filtered AS (
       SELECT p.p_promo_sk, p.p_promo_id, p.p_channel_details
       FROM promotion p
       WHERE p.p_channel_tv = 'Y'
       INTERSECT
       SELECT p2.p_promo_sk, p2.p_promo_id, p2.p_channel_details
       FROM promotion p2
       WHERE p2.p_discount_active = 'Y'
   ),
   promo_channels AS (
       SELECT pf.p_promo_sk,
              pf.p_promo_id,
              TRIM(channel) AS channel
       FROM promo_filtered pf
       CROSS JOIN UNNEST(split(pf.p_channel_details, ',')) AS t(channel)
   ),
   sales_agg AS (
       SELECT
           s.s_store_id,
           w.w_warehouse_id,
           p.p_promo_id,
           td.t_hour,
           SUM(cs.cs_net_profit)                                   AS catalog_profit,
           SUM(ss.ss_net_profit)                                   AS store_profit,
           SUM(ws.ws_net_profit)                                   AS web_profit,
           SUM(cs.cs_ext_sales_price + ss.ss_ext_sales_price + ws.ws_ext_sales_price) AS total_sales,
           COUNT(*)                                                AS txn_cnt
       FROM catalog_sales cs
       JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
       JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
       JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
       JOIN store_sales ss
            ON ss.ss_sold_time_sk = td.t_time_sk
           AND ss.ss_promo_sk = p.p_promo_sk
       JOIN store s ON ss.ss_store_sk = s.s_store_sk
       JOIN web_sales ws
            ON ws.ws_sold_time_sk = td.t_time_sk
           AND ws.ws_promo_sk = p.p_promo_sk
           AND ws.ws_warehouse_sk = w.w_warehouse_sk
       JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
       JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
       JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
       WHERE s.s_manager = 'David Thomas'
         AND we.web_zip = '46060'
         AND i.inv_quantity_on_hand > 1000
         AND td.t_hour BETWEEN 8 AND 12
         AND EXISTS (
               SELECT 1
               FROM inventory i2 TABLESAMPLE BERNOULLI (10)
               WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
                 AND i2.inv_quantity_on_hand > 500
           )
       GROUP BY CUBE (s.s_store_id, w.w_warehouse_id, p.p_promo_id, td.t_hour)
   )
SELECT
    s_store_id,
    w_warehouse_id,
    p_promo_id,
    t_hour,
    catalog_profit,
    store_profit,
    web_profit,
    total_sales,
    txn_cnt,
    RANK() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC)               AS sales_rank,
    (
        SELECT AVG(total_sales)
        FROM sales_agg sa2
        WHERE sa2.s_store_id = sa.s_store_id
    )                                                                           AS avg_store_sales,
    (
        SELECT COUNT(*)
        FROM sales_agg sa3
        WHERE sa3.p_promo_id = sa.p_promo_id
          AND sa3.t_hour = sa.t_hour
    )                                                                           AS promo_hour_txns
FROM sales_agg sa
WHERE p_promo_id IN (SELECT p_promo_id FROM promo_channels)
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
