WITH
  store_side AS (
    SELECT
      ss.ss_ticket_number,
      d.d_date_sk,
      d.d_year,
      t.t_hour,
      ss.ss_ext_sales_price        AS store_sales_amount,
      ss.ss_net_profit            AS store_profit,
      ca.ca_state,
      cd.cd_gender,
      p.p_promo_name,
      p.p_discount_active,
      cp.cp_type,
      inv.inv_quantity_on_hand,
      CASE WHEN ss.ss_net_profit > 0 THEN 1 ELSE 0 END AS store_profit_flag
    FROM store_sales ss
    JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t          ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p    ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN inventory inv  ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
  ),
  web_side AS (
    SELECT
      ws.ws_order_number,
      d.d_date_sk,
      d.d_year,
      t.t_hour,
      ws.ws_ext_sales_price        AS web_sales_amount,
      ws.ws_net_profit             AS web_profit,
      ca.ca_state,
      cd.cd_gender,
      p.p_promo_name,
      p.p_discount_active,
      cp.cp_type,
      inv.inv_quantity_on_hand,
      sm.sm_type,
      w.w_warehouse_name,
      w.w_warehouse_sq_ft,
      wp.wp_url,
      wsit.web_name,
      CASE WHEN ws.ws_net_profit > 0 THEN 1 ELSE 0 END AS web_profit_flag
    FROM web_sales ws
    JOIN date_dim d          ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t          ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p    ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm   ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w    ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv  ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_page wp    ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsit  ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_returned_date_sk = d.d_date_sk
  ),
  combined AS (
    SELECT
      COALESCE(s.d_year, w.d_year)                 AS year,
      COALESCE(s.ca_state, w.ca_state)             AS state,
      s.store_sales_amount,
      w.web_sales_amount,
      s.store_profit,
      w.web_profit,
      COALESCE(s.inv_quantity_on_hand, w.inv_quantity_on_hand) AS inventory_qty,
      COALESCE(s.cp_type, w.cp_type)               AS catalog_type,
      COALESCE(s.p_promo_name, w.p_promo_name)     AS promo_name,
      COALESCE(s.p_discount_active, w.p_discount_active) AS discount_active,
      w.sm_type,
      w.w_warehouse_name,
      w.w_warehouse_sq_ft,
      s.t_hour,
      s.store_profit_flag,
      w.web_profit_flag,
      s.d_date_sk
    FROM store_side s
    FULL OUTER JOIN web_side w
      ON s.d_date_sk = w.d_date_sk
  ),
  agg AS (
    SELECT
      year,
      state,
      SUM(COALESCE(store_sales_amount, 0) + COALESCE(web_sales_amount, 0)) AS total_sales,
      SUM(store_profit_flag)                                    AS store_profit_cnt,
      SUM(web_profit_flag)                                      AS web_profit_cnt,
      AVG(inventory_qty)                                        AS avg_inventory,
      COUNT(DISTINCT promo_name)                                AS distinct_promos,
      COUNT(*)                                                  AS rows_cnt
    FROM combined
    WHERE year IN (2001, 2002)                                   -- predicate 1
      AND state IN ('CA', 'TX')                                   -- predicate 2
      AND t_hour BETWEEN 9 AND 17                                 -- predicate 3
      AND catalog_type = 'ACTIVE'                                 -- predicate 4
      AND w_warehouse_sq_ft > 50000                               -- predicate 5
      AND discount_active = 'Y'                                   -- predicate 6
    GROUP BY CUBE (year, state)
  )
SELECT
  year,
  state,
  total_sales,
  store_profit_cnt,
  web_profit_cnt,
  avg_inventory,
  distinct_promos,
  rows_cnt,
  ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_sales DESC) AS sales_rank,
  (SELECT COUNT(*)
     FROM store_returns sr2
     JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = agg.year)                                   AS store_returns_this_year
FROM agg
ORDER BY year, total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
