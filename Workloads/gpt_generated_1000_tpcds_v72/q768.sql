WITH sales_base AS (
  SELECT
    d.d_year,
    p.p_promo_sk,
    p.p_channel_catalog,
    cc.cc_state,
    cp.cp_catalog_page_number,
    sm.sm_type,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ca.ca_country,
    ws.web_name,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_order_number,
    cs.cs_item_sk,
    inv.inv_quantity_on_hand,
    cr.cr_return_amount,
    sr.sr_return_amt,
    wr.wr_return_amt,
    CASE
      WHEN cs.cs_net_profit > 10000 THEN 'HIGH'
      WHEN cs.cs_net_profit > 5000  THEN 'MEDIUM'
      ELSE 'LOW'
    END AS profit_category
  FROM tpcds.date_dim d
  JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN tpcds.customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  LEFT JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  LEFT JOIN tpcds.store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
  LEFT JOIN tpcds.reason r
    ON r.r_reason_sk = COALESCE(cr.cr_reason_sk, sr.sr_reason_sk, wr.wr_reason_sk)
  LEFT JOIN tpcds.time_dim t
    ON t.t_time_sk = cs.cs_sold_time_sk
  WHERE d.d_year = 2001
    AND p.p_channel_catalog = 'Y'
    AND cc.cc_state = 'CA'
    AND (inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand > 0)
),
aggregated AS (
  SELECT
    d_year,
    p_promo_sk,
    p_channel_catalog,
    cc_state,
    profit_category,
    SUM(cs_net_profit) AS total_profit,
    SUM(cs_quantity) AS total_quantity,
    SUM(COALESCE(cr_return_amount, 0))   AS total_catalog_return,
    SUM(COALESCE(sr_return_amt, 0))      AS total_store_return,
    SUM(COALESCE(wr_return_amt, 0))      AS total_web_return
  FROM sales_base
  GROUP BY d_year, p_promo_sk, p_channel_catalog, cc_state, profit_category
)
SELECT
  d_year,
  p_promo_sk,
  p_channel_catalog,
  cc_state,
  profit_category,
  total_profit,
  total_quantity,
  total_catalog_return,
  total_store_return,
  total_web_return,
  RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY profit_rank
LIMIT 100
