WITH
  sales_agg AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_promo_sk,
      ss.ss_hdemo_sk,
      ss.ss_addr_sk,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      SUM(ss.ss_ext_sales_price) AS sum_sales,
      SUM(ss.ss_net_profit) AS sum_profit,
      COUNT(*) AS cnt_sales
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_demo = 'N'
      AND p.p_channel_dmail = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_item_sk, ss.ss_promo_sk, ss.ss_hdemo_sk,
             ss.ss_addr_sk, ss.ss_sold_date_sk, ss.ss_sold_time_sk
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_promo_sk,
      ws.ws_bill_hdemo_sk,
      ws.ws_ship_hdemo_sk,
      ws.ws_bill_addr_sk,
      ws.ws_ship_addr_sk,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      ws.ws_web_page_sk,
      SUM(ws.ws_ext_sales_price) AS sum_sales,
      SUM(ws.ws_net_profit) AS sum_profit,
      COUNT(*) AS cnt_sales
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND sm.sm_carrier = 'UPS'
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY ws.ws_item_sk, ws.ws_promo_sk, ws.ws_bill_hdemo_sk, ws.ws_ship_hdemo_sk,
             ws.ws_bill_addr_sk, ws.ws_ship_addr_sk, ws.ws_sold_date_sk,
             ws.ws_sold_time_sk, ws.ws_ship_mode_sk, ws.ws_warehouse_sk, ws.ws_web_page_sk
  ),
  returns_agg AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_hdemo_sk,
      sr.sr_addr_sk,
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      SUM(sr.sr_return_amt) AS sum_return_amt,
      COUNT(*) AS cnt_returns
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
    GROUP BY sr.sr_item_sk, sr.sr_hdemo_sk, sr.sr_addr_sk,
             sr.sr_returned_date_sk, sr.sr_return_time_sk
  ),
  combined AS (
    SELECT
      sa.ss_promo_sk                AS promo_sk,
      sa.ss_hdemo_sk                AS hd_demo_sk,
      CAST(NULL AS INTEGER)         AS ship_mode_sk,
      CAST(NULL AS INTEGER)         AS warehouse_sk,
      SUM(sa.sum_sales)             AS sales_sum,
      SUM(sa.sum_profit)            AS profit_sum,
      SUM(sa.cnt_sales)             AS cnt
    FROM sales_agg sa
    GROUP BY sa.ss_promo_sk, sa.ss_hdemo_sk
    UNION ALL
    SELECT
      wa.ws_promo_sk,
      wa.ws_bill_hdemo_sk,
      wa.ws_ship_mode_sk,
      wa.ws_warehouse_sk,
      SUM(wa.sum_sales),
      SUM(wa.sum_profit),
      SUM(wa.cnt_sales)
    FROM web_sales_agg wa
    GROUP BY wa.ws_promo_sk, wa.ws_bill_hdemo_sk,
             wa.ws_ship_mode_sk, wa.ws_warehouse_sk
    UNION ALL
    SELECT
      CAST(NULL AS INTEGER),
      ra.sr_hdemo_sk,
      CAST(NULL AS INTEGER),
      CAST(NULL AS INTEGER),
      -SUM(ra.sum_return_amt),
      0,
      SUM(ra.cnt_returns)
    FROM returns_agg ra
    GROUP BY ra.sr_hdemo_sk
  ),
  final AS (
    SELECT
      p.p_promo_name,
      sm.sm_carrier,
      w.w_warehouse_name,
      ib.ib_lower_bound,
      SUM(c.sales_sum)   AS total_sales,
      SUM(c.profit_sum)  AS total_profit,
      SUM(c.cnt)         AS total_cnt
    FROM combined c
    LEFT JOIN promotion p        ON c.promo_sk    = p.p_promo_sk
    LEFT JOIN ship_mode sm       ON c.ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w        ON c.warehouse_sk = w.w_warehouse_sk
    LEFT JOIN household_demographics hd ON c.hd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib     ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000
    GROUP BY ROLLUP (p.p_promo_name, sm.sm_carrier, w.w_warehouse_name, ib.ib_lower_bound)
  )
SELECT
  p_promo_name,
  sm_carrier,
  w_warehouse_name,
  ib_lower_bound,
  total_sales,
  total_profit,
  total_cnt,
  ROW_NUMBER() OVER (PARTITION BY p_promo_name ORDER BY total_sales DESC) AS rank_by_sales
FROM final
ORDER BY total_sales DESC
LIMIT 100
