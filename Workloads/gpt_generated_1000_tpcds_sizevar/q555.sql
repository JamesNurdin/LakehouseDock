WITH
  cs_agg AS (
    SELECT
      cs.cs_order_number,
      cs.cs_bill_customer_sk,
      cs.cs_item_sk,
      cs.cs_net_paid,
      cs.cs_quantity,
      cs.cs_sold_date_sk AS sold_date_sk,
      d.d_year,
      i.i_brand,
      p.p_discount_active,
      sm.sm_carrier,
      c.c_customer_id,
      ca.ca_city,
      cd.cd_gender,
      hd.hd_income_band_sk,
      t.t_hour,
      ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_net_paid DESC) AS purchase_rank
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2000
      AND sm.sm_carrier = 'GERMA'
      AND p.p_discount_active = 'Y'
      AND i.i_brand = 'BrandX'
      AND ca.ca_state = 'CA'
  ),
  ws_agg AS (
    SELECT
      ws.ws_order_number,
      ws.ws_bill_customer_sk,
      ws.ws_item_sk,
      ws.ws_net_paid,
      ws.ws_quantity,
      d2.d_year,
      i2.i_brand,
      p2.p_discount_active,
      sm2.sm_carrier,
      wp.wp_type,
      c2.c_first_name,
      ca2.ca_city,
      cd2.cd_gender,
      hd2.hd_income_band_sk,
      t2.t_hour,
      ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_net_paid DESC) AS purchase_rank_ws
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    WHERE d2.d_year = 2000
      AND sm2.sm_carrier = 'GERMA'
      AND p2.p_discount_active = 'Y'
      AND i2.i_brand = 'BrandX'
      AND wp.wp_type = 'article'
  ),
  store_ret AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_customer_sk,
      sr.sr_return_quantity,
      d3.d_year,
      i3.i_brand,
      c3.c_customer_id,
      ca3.ca_city,
      cd3.cd_gender,
      hd3.hd_income_band_sk,
      t3.t_hour
    FROM store_returns sr
    JOIN date_dim d3 ON sr.sr_returned_date_sk = d3.d_date_sk
    JOIN item i3 ON sr.sr_item_sk = i3.i_item_sk
    JOIN customer c3 ON sr.sr_customer_sk = c3.c_customer_sk
    JOIN customer_address ca3 ON sr.sr_addr_sk = ca3.ca_address_sk
    JOIN customer_demographics cd3 ON sr.sr_cdemo_sk = cd3.cd_demo_sk
    JOIN household_demographics hd3 ON sr.sr_hdemo_sk = hd3.hd_demo_sk
    JOIN time_dim t3 ON sr.sr_return_time_sk = t3.t_time_sk
    WHERE d3.d_year = 2000
  ),
  web_ret AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_refunded_customer_sk,
      wr.wr_return_quantity,
      d4.d_year,
      i4.i_brand,
      c4.c_customer_id,
      ca4.ca_city,
      cd4.cd_gender,
      hd4.hd_income_band_sk,
      t4.t_hour,
      wp4.wp_type
    FROM web_returns wr
    JOIN date_dim d4 ON wr.wr_returned_date_sk = d4.d_date_sk
    JOIN item i4 ON wr.wr_item_sk = i4.i_item_sk
    JOIN customer c4 ON wr.wr_refunded_customer_sk = c4.c_customer_sk
    JOIN customer_address ca4 ON wr.wr_refunded_addr_sk = ca4.ca_address_sk
    JOIN customer_demographics cd4 ON wr.wr_refunded_cdemo_sk = cd4.cd_demo_sk
    JOIN household_demographics hd4 ON wr.wr_refunded_hdemo_sk = hd4.hd_demo_sk
    JOIN time_dim t4 ON wr.wr_returned_time_sk = t4.t_time_sk
    JOIN web_page wp4 ON wr.wr_web_page_sk = wp4.wp_web_page_sk
    WHERE d4.d_year = 2000
  ),
  order_exceptions AS (
    SELECT cs_order_number FROM cs_agg
    EXCEPT
    SELECT ws_order_number FROM ws_agg
  ),
  order_intersections AS (
    SELECT sr_item_sk FROM store_ret
    INTERSECT
    SELECT wr_item_sk FROM web_ret
  ),
  full_cc_ws AS (
    SELECT
      cc.cc_call_center_id,
      cc.cc_name,
      ws.web_site_id,
      ws.web_name,
      d5.d_date_sk AS open_date_sk
    FROM call_center cc
    LEFT JOIN date_dim d5 ON cc.cc_open_date_sk = d5.d_date_sk
    FULL OUTER JOIN web_site ws ON d5.d_date_sk = ws.web_open_date_sk
    WHERE d5.d_year = 2000
  )
SELECT
  oe.cs_order_number,
  wsagg.ws_order_number AS ws_order_num,
  fccws.cc_call_center_id,
  fccws.cc_name,
  SUM(csagg.cs_net_paid) AS total_cs_net_paid,
  AVG(wsagg.ws_net_paid) AS avg_ws_net_paid,
  COUNT(DISTINCT csagg.cs_item_sk) AS distinct_items_sold,
  MIN(csagg.cs_quantity) AS min_quantity,
  MAX(wsagg.ws_quantity) AS max_quantity,
  COUNT(DISTINCT sr.sr_item_sk) AS store_return_items,
  COUNT(DISTINCT wr.wr_item_sk) AS web_return_items
FROM order_exceptions oe
LEFT JOIN cs_agg csagg ON oe.cs_order_number = csagg.cs_order_number
LEFT JOIN ws_agg wsagg ON oe.cs_order_number = wsagg.ws_order_number
LEFT JOIN store_ret sr ON csagg.cs_item_sk = sr.sr_item_sk
LEFT JOIN web_ret wr ON csagg.cs_item_sk = wr.wr_item_sk
FULL OUTER JOIN full_cc_ws fccws ON csagg.sold_date_sk = fccws.open_date_sk
WHERE csagg.purchase_rank = 1
  AND wsagg.purchase_rank_ws = 1
GROUP BY
  oe.cs_order_number,
  wsagg.ws_order_number,
  fccws.cc_call_center_id,
  fccws.cc_name
ORDER BY total_cs_net_paid DESC
OFFSET 10 LIMIT 100
