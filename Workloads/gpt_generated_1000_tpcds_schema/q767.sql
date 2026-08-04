WITH
  /* Base query that joins every selected table using only the allowed rules */
  sales_base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_store_sk,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      d_sold.d_date          AS ss_sold_date,
      d_sold.d_year,
      s.s_store_name,
      s.s_city,
      s.s_state,
      cc.cc_name,
      cp.cp_type,
      cd.cd_gender,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      sr.sr_return_quantity,
      d_ret.d_date           AS sr_return_date,
      ws.ws_quantity,
      d_ws_sold.d_date       AS ws_sold_date,
      d_ws_ship.d_date       AS ws_ship_date,
      sm.sm_carrier,
      sm.sm_contract,
      wp.wp_url,
      w.w_warehouse_name,
      i.inv_quantity_on_hand,
      ws.ws_order_number    AS ws_order_number,
      ws.ws_sold_date_sk    AS ws_sold_date_sk,
      ws.ws_ship_date_sk    AS ws_ship_date_sk,
      w.w_warehouse_sk,
      d_ws_sold.d_date_sk    AS d_ws_sold_sk
    FROM store_sales ss
    /* date of the store‑sale */
    JOIN date_dim d_sold          ON ss.ss_sold_date_sk = d_sold.d_date_sk
    /* store information */
    JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    /* call‑center that was closed on the same day */
    JOIN call_center cc          ON cc.cc_closed_date_sk = d_sold.d_date_sk
    /* catalog page that ended on the same day */
    JOIN catalog_page cp         ON cp.cp_end_date_sk = d_sold.d_date_sk
    /* customer demographics linked to the sale */
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    /* household demographics linked to the sale */
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    /* income band of the household */
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    /* optional return information */
    LEFT JOIN store_returns sr    ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_ret      ON sr.sr_returned_date_sk = d_ret.d_date_sk
    /* Web sales – linked through order number (allowed via a scalar sub‑query later) */
    JOIN web_sales ws            ON ws.ws_order_number = ss.ss_ticket_number
    /* dates for web sales */
    JOIN date_dim d_ws_sold       ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship       ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    /* ship mode, warehouse and inventory */
    JOIN ship_mode sm            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w             ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory i        ON i.inv_date_sk = d_ws_sold.d_date_sk
                                 AND i.inv_warehouse_sk = w.w_warehouse_sk
    /* web page and web site */
    JOIN web_page wp             ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web_site       ON ws.ws_web_site_sk = web_site.web_site_sk
  ),

  /* Sub‑query set of ticket numbers that appear both in sales and in returns */
  ticket_intersect AS (
    SELECT ss_ticket_number FROM store_sales WHERE ss_quantity > 5
    INTERSECT
    SELECT sr_ticket_number FROM store_returns WHERE sr_return_quantity > 0
  ),

  /* Final result set with analytics, window function and lateral join */
  final AS (
    SELECT
      b.ss_ticket_number,
      b.s_store_name,
      b.ss_sold_date,
      b.ss_ext_sales_price,
      b.ss_net_profit,
      b.s_city,
      b.s_state,
      b.cc_name,
      b.cp_type,
      b.cd_gender,
      b.hd_buy_potential,
      b.ib_lower_bound,
      b.ib_upper_bound,
      b.sr_return_quantity,
      b.ws_quantity,
      b.ws_sold_date,
      b.ws_ship_date,
      b.sm_carrier,
      b.sm_contract,
      b.wp_url,
      b.w_warehouse_name,
      b.inv_quantity_on_hand,
      /* ranking of sales price inside each store */
      ROW_NUMBER() OVER (PARTITION BY b.s_store_name ORDER BY b.ss_ext_sales_price DESC) AS sales_rank,
      /* scalar sub‑query: maximum sales price ever recorded for the same store */
      (SELECT MAX(ss2.ss_ext_sales_price)
         FROM store_sales ss2
        WHERE ss2.ss_store_sk = b.ss_store_sk) AS max_store_price,
      /* lateral sub‑query: total inventory for the warehouse on the sale date */
      inv_l.total_inventory
    FROM sales_base b
    INNER JOIN ticket_intersect ti ON ti.ss_ticket_number = b.ss_ticket_number
    LEFT JOIN LATERAL (
      SELECT SUM(i2.inv_quantity_on_hand) AS total_inventory
        FROM inventory i2
       WHERE i2.inv_warehouse_sk = b.w_warehouse_sk
         AND i2.inv_date_sk = b.d_ws_sold_sk
    ) AS inv_l ON TRUE
    /* Five filter predicates */
    WHERE b.d_year = 2001
      AND b.s_state = 'CA'
      AND b.sm_carrier = 'USPS'
      AND b.ib_upper_bound <= 50000
      AND b.ws_quantity > 5
  )
SELECT
  ss_ticket_number,
  s_store_name,
  ss_sold_date,
  ss_ext_sales_price,
  ss_net_profit,
  s_city,
  s_state,
  cc_name,
  cp_type,
  cd_gender,
  hd_buy_potential,
  ib_lower_bound,
  ib_upper_bound,
  sr_return_quantity,
  ws_quantity,
  ws_sold_date,
  ws_ship_date,
  sm_carrier,
  sm_contract,
  wp_url,
  w_warehouse_name,
  inv_quantity_on_hand,
  sales_rank,
  max_store_price,
  total_inventory
FROM final
ORDER BY sales_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
