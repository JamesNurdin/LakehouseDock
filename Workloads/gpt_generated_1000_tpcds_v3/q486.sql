WITH base AS (
  SELECT
    d.d_date,
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    i.i_color,
    w.w_warehouse_name,
    cc.cc_name,
    p.p_promo_name,
    r.r_reason_desc,
    cd.cd_gender,
    hd.hd_buy_potential,
    SUM(COALESCE(ss.ss_net_profit, 0)) AS ss_net_profit,
    SUM(COALESCE(cs.cs_net_profit, 0)) AS cs_net_profit,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS ws_net_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS sr_net_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS wr_net_loss
  FROM tpcds.date_dim d
  JOIN tpcds.call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN tpcds.item i
    ON i.i_item_sk = cs.cs_item_sk
  JOIN tpcds.promotion p
    ON p.p_promo_sk = cs.cs_promo_sk
  JOIN tpcds.warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = i.i_item_sk
  JOIN tpcds.reason r
    ON r.r_reason_sk = sr.sr_reason_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
  JOIN tpcds.web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
  JOIN tpcds.web_site wsite
    ON wsite.web_site_sk = ws.ws_web_site_sk
  JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.customer_demographics cd
    ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
  JOIN tpcds.household_demographics hd
    ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
  WHERE d.d_year = 2001
    AND cc.cc_state = 'CA'
    AND w.w_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND i.i_color = 'RED'
    AND r.r_reason_desc = 'Customer not satisfied'
    AND cd.cd_gender = 'M'
    AND hd.hd_buy_potential = 'HIGH'
  GROUP BY
    d.d_date,
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    i.i_color,
    w.w_warehouse_name,
    cc.cc_name,
    p.p_promo_name,
    r.r_reason_desc,
    cd.cd_gender,
    hd.hd_buy_potential
)
SELECT
  d_date,
  d_year,
  i_item_id,
  i_product_name,
  i_color,
  w_warehouse_name,
  cc_name,
  p_promo_name,
  r_reason_desc,
  cd_gender,
  hd_buy_potential,
  ss_net_profit,
  cs_net_profit,
  ws_net_profit,
  (ss_net_profit + cs_net_profit + ws_net_profit) AS total_net_profit,
  sr_net_loss,
  wr_net_loss,
  CASE
    WHEN (ss_net_profit + cs_net_profit + ws_net_profit) > 500000 THEN 'HIGH'
    WHEN (ss_net_profit + cs_net_profit + ws_net_profit) > 200000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  ROW_NUMBER() OVER (
    PARTITION BY d_year
    ORDER BY (ss_net_profit + cs_net_profit + ws_net_profit) DESC
  ) AS profit_rank
FROM base
ORDER BY total_net_profit DESC
LIMIT 20
