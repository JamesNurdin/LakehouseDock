WITH base AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_store_sk,
    ss.ss_customer_sk,
    ss.ss_cdemo_sk,
    ss.ss_hdemo_sk,
    ss.ss_addr_sk,
    ss.ss_promo_sk,
    ss.ss_ticket_number,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit,
    i.i_item_id,
    i.i_current_price,
    s.s_store_id,
    s.s_state,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ca.ca_city,
    p.p_promo_id,
    p.p_discount_active,
    sr.sr_net_loss,
    cr.cr_net_loss,
    wr.wr_net_loss,
    r.r_reason_desc,
    cc.cc_name,
    cp.cp_description,
    sm.sm_code,
    w.w_warehouse_name
  FROM store_sales ss
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
  LEFT JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
    OR r.r_reason_sk = cr.cr_reason_sk
    OR r.r_reason_sk = wr.wr_reason_sk
  LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE i.i_current_price > 100
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND sm.sm_code = 'AIR'
    AND cp.cp_end_date_sk > 2451000
)
SELECT DISTINCT
  i_item_id,
  s_store_id,
  c_customer_id,
  ca_city,
  cd_gender,
  hd_income_band_sk,
  ss_net_paid,
  ss_net_profit,
  COALESCE(sr_net_loss, 0)          AS store_return_loss,
  COALESCE(cr_net_loss, 0)          AS catalog_return_loss,
  COALESCE(wr_net_loss, 0)          AS web_return_loss,
  (ss_net_paid - COALESCE(sr_net_loss, 0) - COALESCE(cr_net_loss, 0) - COALESCE(wr_net_loss, 0)) AS net_contribution,
  ROW_NUMBER() OVER (
    PARTITION BY i_item_id
    ORDER BY (ss_net_paid - COALESCE(sr_net_loss, 0) - COALESCE(cr_net_loss, 0) - COALESCE(wr_net_loss, 0)) DESC
  )                                 AS sales_rank,
  CASE WHEN ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
  r_reason_desc,
  cc_name,
  cp_description,
  sm_code,
  w_warehouse_name
FROM base
ORDER BY net_contribution DESC
LIMIT 100
