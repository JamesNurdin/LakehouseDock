WITH
  store_agg AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_promo_sk,
      SUM(ss.ss_net_profit)         AS total_store_profit,
      SUM(ss.ss_quantity)           AS total_store_qty
    FROM tpcds.store_sales ss
    GROUP BY ss.ss_sold_date_sk,
             ss.ss_sold_time_sk,
             ss.ss_cdemo_sk,
             ss.ss_hdemo_sk,
             ss.ss_promo_sk
  ),
  catalog_agg AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      cs.cs_promo_sk,
      SUM(cs.cs_net_profit)         AS total_catalog_profit,
      SUM(cs.cs_quantity)           AS total_catalog_qty
    FROM tpcds.catalog_sales cs
    GROUP BY cs.cs_sold_date_sk,
             cs.cs_sold_time_sk,
             cs.cs_call_center_sk,
             cs.cs_catalog_page_sk,
             cs.cs_ship_mode_sk,
             cs.cs_warehouse_sk,
             cs.cs_promo_sk
  ),
  web_agg AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      ws.ws_promo_sk,
      ws.ws_web_page_sk,
      ws.ws_order_number,
      SUM(ws.ws_net_profit)         AS total_web_profit,
      SUM(ws.ws_quantity)           AS total_web_qty
    FROM tpcds.web_sales ws
    GROUP BY ws.ws_sold_date_sk,
             ws.ws_sold_time_sk,
             ws.ws_ship_mode_sk,
             ws.ws_warehouse_sk,
             ws.ws_promo_sk,
             ws.ws_web_page_sk,
             ws.ws_order_number
  )
SELECT
  d.d_year,
  w.w_warehouse_name,
  p.p_promo_name,
  CASE WHEN SUM(sa.total_store_profit) > 50000 THEN 'High' ELSE 'Medium' END AS store_profit_category,
  SUM(sa.total_store_profit)                       AS store_profit,
  SUM(ca.total_catalog_profit)                    AS catalog_profit,
  SUM(wa.total_web_profit)                        AS web_profit,
  SUM(sa.total_store_profit + ca.total_catalog_profit + wa.total_web_profit) AS total_profit,
  (
    SELECT COUNT(*)
    FROM (
      SELECT cs_order_number FROM tpcds.catalog_sales
      EXCEPT
      SELECT ws_order_number FROM tpcds.web_sales
    ) AS diff
  ) AS cat_not_web_order_cnt
FROM store_agg sa
JOIN tpcds.date_dim d               ON sa.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t               ON sa.ss_sold_time_sk = t.t_time_sk
JOIN tpcds.customer_demographics cd ON sa.ss_cdemo_sk   = cd.cd_demo_sk
JOIN tpcds.household_demographics hd ON sa.ss_hdemo_sk   = hd.hd_demo_sk
JOIN tpcds.income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.promotion p               ON sa.ss_promo_sk   = p.p_promo_sk
JOIN catalog_agg ca                  ON ca.cs_sold_date_sk = d.d_date_sk
                                      AND ca.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.call_center cc           ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp           ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm              ON ca.cs_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w               ON ca.cs_warehouse_sk   = w.w_warehouse_sk
FULL OUTER JOIN tpcds.inventory i    ON i.inv_warehouse_sk = w.w_warehouse_sk
                                      AND i.inv_date_sk     = d.d_date_sk
JOIN web_agg wa                      ON wa.ws_sold_date_sk = d.d_date_sk
                                      AND wa.ws_sold_time_sk = t.t_time_sk
JOIN tpcds.web_page wp               ON wa.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2001
  AND t.t_hour BETWEEN 8 AND 18
  AND cd.cd_gender = 'F'
  AND hd.hd_buy_potential = '5000-10000'
  AND p.p_discount_active = 'Y'
  AND i.inv_quantity_on_hand > 200
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr
        WHERE wr.wr_order_number = wa.ws_order_number
          AND wr.wr_return_quantity > 10
      )
GROUP BY d.d_year,
         w.w_warehouse_name,
         p.p_promo_name,
         cd.cd_gender,
         hd.hd_buy_potential
ORDER BY total_profit DESC
LIMIT 100
