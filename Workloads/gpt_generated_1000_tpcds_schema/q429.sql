WITH
  store_cte AS (
    SELECT
      ss.ss_sold_date_sk               AS sold_date_sk,
      ss.ss_sold_time_sk               AS sold_time_sk,
      ss.ss_item_sk                    AS item_sk,
      i.i_item_id                      AS item_id,
      ss.ss_store_sk                   AS store_sk,
      s.s_store_id                     AS store_id,
      ss.ss_promo_sk                   AS promo_sk,
      p.p_promo_id                     AS promo_id,
      cs.cs_call_center_sk             AS call_center_sk,
      cc.cc_name                       AS call_center_name,
      dd.d_year                        AS year,
      hd.hd_vehicle_count             AS vehicle_cnt,
      ca.ca_address_sk                 AS address_sk,
      ca.ca_state                      AS address_state,
      ss.ss_net_profit                 AS store_profit,
      inv.inv_quantity_on_hand         AS inv_qty,
      w.w_warehouse_sk                 AS warehouse_sk,
      w.w_warehouse_name               AS warehouse_name,
      cs.cs_quantity                   AS cs_quantity,
      cs.cs_net_profit                 AS cs_net_profit,
      cc.cc_state                      AS cc_state,
      ss.ss_wholesale_cost             AS ss_wholesale_cost
    FROM store_sales ss
    JOIN date_dim dd               ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN time_dim td               ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
    JOIN store s                   ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p          ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr     ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca  ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv        ON ss.ss_item_sk = inv.inv_item_sk
    LEFT JOIN warehouse w          ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_sales cs     ON cs.cs_item_sk = ss.ss_item_sk
                                   AND cs.cs_sold_date_sk = ss.ss_sold_date_sk
    LEFT JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE dd.d_year = 2001
      AND i.i_category = 'Electronics'
      AND hd.hd_vehicle_count > 0
      AND cc.cc_state = 'CA'
      AND ss.ss_wholesale_cost > 10
      AND inv.inv_quantity_on_hand < 500
  ),

  web_cte AS (
    SELECT
      ws.ws_sold_date_sk               AS sold_date_sk,
      ws.ws_sold_time_sk               AS sold_time_sk,
      ws.ws_item_sk                    AS item_sk,
      i.i_item_id                      AS item_id,
      ws.ws_web_site_sk                AS web_site_sk,
      wz.web_name                      AS web_site_name,
      ws.ws_promo_sk                   AS promo_sk,
      p.p_promo_id                     AS promo_id,
      hd.hd_vehicle_count             AS vehicle_cnt,
      ca.ca_address_sk                 AS address_sk,
      ca.ca_state                      AS address_state,
      ws.ws_net_paid                   AS web_profit,
      ws.ws_sales_price                AS sales_price,
      inv.inv_quantity_on_hand         AS inv_qty,
      w.w_warehouse_sk                 AS warehouse_sk,
      w.w_warehouse_name               AS warehouse_name,
      wr.wr_return_quantity            AS wr_return_qty,
      ws.ws_sales_price                AS ws_sales_price,
      wd.d_year                        AS year
    FROM web_sales ws
    JOIN date_dim wd               ON ws.ws_sold_date_sk = wd.d_date_sk
    JOIN time_dim td               ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i                    ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wz               ON ws.ws_web_site_sk = wz.web_site_sk
    LEFT JOIN promotion p          ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca  ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv        ON ws.ws_item_sk = inv.inv_item_sk
    LEFT JOIN warehouse w          ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr       ON ws.ws_order_number = wr.wr_order_number
    WHERE wd.d_year = 2001
      AND i.i_category = 'Electronics'
      AND hd.hd_vehicle_count > 0
      AND ws.ws_sales_price > 500
      AND inv.inv_quantity_on_hand < 500
  ),

  full_join_cte AS (
    SELECT
      COALESCE(s.sold_date_sk, w.sold_date_sk) AS date_sk,
      s.store_id,
      w.web_site_name,
      s.store_profit,
      w.web_profit,
      s.item_id,
      w.item_id      AS web_item_id,
      s.item_sk,
      s.vehicle_cnt,
      s.address_state AS store_state,
      w.address_state AS web_state,
      s.inv_qty      AS store_inv_qty,
      w.inv_qty      AS web_inv_qty,
      s.warehouse_name AS store_warehouse,
      w.warehouse_name AS web_warehouse
    FROM store_cte s
    FULL OUTER JOIN web_cte w
      ON s.sold_date_sk = w.sold_date_sk
  ),

  ranked_cte AS (
    SELECT
      fj.*,
      ROW_NUMBER() OVER (PARTITION BY fj.date_sk ORDER BY COALESCE(fj.store_profit, 0) + COALESCE(fj.web_profit, 0) DESC) AS rn
    FROM full_join_cte fj
    WHERE EXISTS (
      SELECT 1
      FROM catalog_sales cs
      WHERE cs.cs_item_sk = fj.item_sk
        AND cs.cs_sold_date_sk = fj.date_sk
        AND cs.cs_quantity > 1
    )
  ),

  final_union AS (
    SELECT
      date_sk,
      store_id,
      web_site_name,
      store_profit,
      web_profit,
      item_id,
      rn
    FROM ranked_cte
    WHERE rn <= 5
    UNION DISTINCT
    SELECT
      cs.cs_sold_date_sk  AS date_sk,
      NULL                AS store_id,
      cc.cc_name          AS web_site_name,
      cs.cs_net_profit    AS store_profit,
      NULL                AS web_profit,
      i.i_item_id         AS item_id,
      1                   AS rn
    FROM catalog_sales cs
    JOIN item i               ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d           ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
      AND cc.cc_state = 'CA'
  )
SELECT *
FROM final_union
ORDER BY date_sk, store_profit DESC
LIMIT 100
