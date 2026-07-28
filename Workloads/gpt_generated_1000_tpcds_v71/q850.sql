WITH
  -- Aliases for date_dim used in many roles
  d_sold        AS (SELECT * FROM date_dim),
  d_cs_sold     AS (SELECT * FROM date_dim),
  d_cs_ship     AS (SELECT * FROM date_dim),
  d_ws_sold     AS (SELECT * FROM date_dim),
  d_p_start     AS (SELECT * FROM date_dim),
  d_p_end       AS (SELECT * FROM date_dim),
  d_wp_creation AS (SELECT * FROM date_dim),
  d_wp_access   AS (SELECT * FROM date_dim),
  d_wr_returned AS (SELECT * FROM date_dim),
  d_sr_returned AS (SELECT * FROM date_dim),
  d_inv         AS (SELECT * FROM date_dim),
  d_store_closed AS (SELECT * FROM date_dim)

SELECT
  s.s_store_name,
  d_sold.d_year,
  SUM(ss.ss_net_paid)                     AS store_sales_total,
  SUM(cs.cs_net_paid)                     AS catalog_sales_total,
  SUM(ws.ws_net_paid)                     AS web_sales_total,
  COUNT(DISTINCT p.p_promo_id)            AS distinct_promos_used,
  CASE
    WHEN SUM(ss.ss_net_profit) > 100000 THEN 'HIGH'
    ELSE 'LOW'
  END                                      AS profit_category,
  RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
FROM
  store_sales          ss
  JOIN store           s          ON ss.ss_store_sk = s.s_store_sk
  JOIN d_sold          d_sold    ON ss.ss_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim        t_sold    ON ss.ss_sold_time_sk = t_sold.t_time_sk
  JOIN customer_demographics cd   ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN promotion       p         ON ss.ss_promo_sk = p.p_promo_sk
  JOIN d_p_start       d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
  JOIN d_p_end         d_p_end   ON p.p_end_date_sk = d_p_end.d_date_sk
  -- Catalog Sales linked through the same promotion
  JOIN catalog_sales   cs        ON cs.cs_promo_sk = p.p_promo_sk
  JOIN d_cs_sold       d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
  JOIN d_cs_ship       d_cs_ship ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
  JOIN time_dim        t_cs_sold ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
  JOIN ship_mode       sm_cs     ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
  JOIN warehouse       w_cs      ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
  -- Web Sales linked through the same promotion
  JOIN web_sales       ws        ON ws.ws_promo_sk = p.p_promo_sk
  JOIN d_ws_sold       d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  JOIN time_dim        t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
  JOIN ship_mode       sm_ws     ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN warehouse       w_ws      ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
  JOIN web_page        wp        ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN d_wp_creation   d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
  JOIN d_wp_access     d_wp_access   ON wp.wp_access_date_sk   = d_wp_access.d_date_sk
  -- Web Returns
  JOIN web_returns     wr        ON wr.wr_order_number = ws.ws_order_number
  JOIN d_wr_returned   d_wr_returned ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
  JOIN time_dim        t_wr_returned ON wr.wr_returned_time_sk = t_wr_returned.t_time_sk
  JOIN reason          r_wr      ON wr.wr_reason_sk = r_wr.r_reason_sk
  -- Store Returns
  JOIN store_returns   sr        ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN d_sr_returned   d_sr_returned ON sr.sr_returned_date_sk = d_sr_returned.d_date_sk
  JOIN time_dim        t_sr_returned ON sr.sr_return_time_sk = t_sr_returned.t_time_sk
  JOIN reason          r_sr      ON sr.sr_reason_sk = r_sr.r_reason_sk
  -- Inventory (through the warehouse used by catalog sales)
  JOIN inventory       inv       ON inv.inv_warehouse_sk = w_cs.w_warehouse_sk
  JOIN d_inv           d_inv     ON inv.inv_date_sk = d_inv.d_date_sk
  -- Store closed date
  JOIN d_store_closed  d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE
  d_sold.d_year = 2002
GROUP BY
  s.s_store_name,
  d_sold.d_year
ORDER BY
  store_sales_total DESC
LIMIT 100
