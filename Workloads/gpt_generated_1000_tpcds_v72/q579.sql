WITH
  ss AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_net_profit,
      d1.d_year      AS year,
      t1.t_time      AS sold_time,
      i.i_brand,
      c.c_customer_id,
      cd1.cd_gender,
      hd1.hd_buy_potential,
      s.s_store_name AS store_name,
      p.p_promo_name AS promotion_name
    FROM store_sales ss
    JOIN date_dim d1               ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1               ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd1 ON ss.ss_cdemo_sk = cd1.cd_demo_sk
    JOIN household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN store s                   ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p         ON ss.ss_promo_sk = p.p_promo_sk
  ),
  cs AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_net_profit,
      d2.d_year            AS year,
      t2.t_time            AS sold_time,
      p_cs.p_promo_name    AS promotion_name,
      cc.cc_name           AS call_center_name,
      cp.cp_department     AS catalog_department,
      sm_cs.sm_type        AS ship_mode_type
    FROM catalog_sales cs
    JOIN date_dim d2               ON cs.cs_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2               ON cs.cs_sold_time_sk = t2.t_time_sk
    JOIN item i                    ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c_bill           ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship           ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cs           ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    LEFT JOIN promotion p_cs       ON cs.cs_promo_sk = p_cs.p_promo_sk
  ),
  ws AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_net_profit,
      d3.d_year            AS year,
      t3.t_time            AS sold_time,
      ws_site.web_name     AS web_site_name,
      p_ws.p_promo_name    AS promotion_name,
      sm_ws.sm_type        AS ship_mode_type
    FROM web_sales ws
    JOIN date_dim d3               ON ws.ws_sold_date_sk = d3.d_date_sk
    JOIN time_dim t3               ON ws.ws_sold_time_sk = t3.t_time_sk
    JOIN item i                    ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill_ws        ON ws.ws_bill_customer_sk = c_bill_ws.c_customer_sk
    JOIN customer c_ship_ws        ON ws.ws_ship_customer_sk = c_ship_ws.c_customer_sk
    JOIN web_site ws_site          ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm_ws           ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN promotion p_ws       ON ws.ws_promo_sk = p_ws.p_promo_sk
  ),
  cr AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_net_loss,
      d4.d_year            AS year,
      t4.t_time            AS return_time,
      r.r_reason_desc      AS return_reason,
      cc.cc_name           AS call_center_name,
      cp.cp_department     AS catalog_department,
      sm_cr.sm_type        AS ship_mode_type
    FROM catalog_returns cr
    JOIN date_dim d4               ON cr.cr_returned_date_sk = d4.d_date_sk
    JOIN time_dim t4               ON cr.cr_returned_time_sk = t4.t_time_sk
    JOIN item i                    ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c_refund        ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer c_return        ON cr.cr_returning_customer_sk = c_return.c_customer_sk
    JOIN call_center cc            ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp           ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cr           ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN reason r                  ON cr.cr_reason_sk = r.r_reason_sk
  ),
  wr AS (
    SELECT
      wr.wr_item_sk,
      wr.wr_returned_date_sk,
      wr.wr_returned_time_sk,
      wr.wr_net_loss,
      d5.d_year            AS year,
      t5.t_time            AS return_time,
      r.r_reason_desc      AS return_reason,
      ws.ws_order_number   AS related_order_number
    FROM web_returns wr
    JOIN date_dim d5               ON wr.wr_returned_date_sk = d5.d_date_sk
    JOIN time_dim t5               ON wr.wr_returned_time_sk = t5.t_time_sk
    JOIN item i                    ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c_refund_wr     ON wr.wr_refunded_customer_sk = c_refund_wr.c_customer_sk
    JOIN customer c_return_wr     ON wr.wr_returning_customer_sk = c_return_wr.c_customer_sk
    JOIN reason r                  ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_sales ws              ON wr.wr_order_number = ws.ws_order_number
  )
SELECT
  ss.store_name,
  ss.year,
  COALESCE(SUM(ss.ss_net_profit), 0)               AS store_sales_profit,
  COALESCE(SUM(cs.cs_net_profit), 0)               AS catalog_sales_profit,
  COALESCE(SUM(ws.ws_net_profit), 0)               AS web_sales_profit,
  COALESCE(SUM(cr.cr_net_loss), 0)                 AS catalog_returns_loss,
  COALESCE(SUM(wr.wr_net_loss), 0)                 AS web_returns_loss,
  (COALESCE(SUM(ss.ss_net_profit), 0) +
   COALESCE(SUM(cs.cs_net_profit), 0) +
   COALESCE(SUM(ws.ws_net_profit), 0) -
   COALESCE(SUM(cr.cr_net_loss), 0) -
   COALESCE(SUM(wr.wr_net_loss), 0))               AS total_profit,
  RANK() OVER (ORDER BY
    (COALESCE(SUM(ss.ss_net_profit), 0) +
     COALESCE(SUM(cs.cs_net_profit), 0) +
     COALESCE(SUM(ws.ws_net_profit), 0) -
     COALESCE(SUM(cr.cr_net_loss), 0) -
     COALESCE(SUM(wr.wr_net_loss), 0)) DESC)   AS profit_rank
FROM ss
LEFT JOIN cs ON ss.ss_item_sk = cs.cs_item_sk
               AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
LEFT JOIN ws ON ss.ss_item_sk = ws.ws_item_sk
               AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
LEFT JOIN cr ON ss.ss_item_sk = cr.cr_item_sk
               AND ss.ss_sold_date_sk = cr.cr_returned_date_sk
LEFT JOIN wr ON ss.ss_item_sk = wr.wr_item_sk
               AND ss.ss_sold_date_sk = wr.wr_returned_date_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = ss.ss_item_sk
          AND cr2.cr_returned_date_sk = ss.ss_sold_date_sk
      )
GROUP BY ss.store_name, ss.year
ORDER BY total_profit DESC, ss.store_name
