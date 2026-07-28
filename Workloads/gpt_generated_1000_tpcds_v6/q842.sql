WITH cs_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 2
      AND cs.cs_ext_discount_amt < 500
      AND cs.cs_wholesale_cost > 20
    GROUP BY cs.cs_call_center_sk,
             cs.cs_catalog_page_sk,
             cs.cs_ship_mode_sk,
             cs.cs_promo_sk,
             cs.cs_bill_cdemo_sk,
             cs.cs_bill_hdemo_sk,
             cs.cs_bill_addr_sk
)
SELECT
    cc.cc_name,
    cp.cp_description,
    sm.sm_type,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    ca.ca_city,
    cs_agg.total_sales,
    cs_agg.total_profit,
    ws.ws_avg_net_paid,
    sr.sr_total_return_amt
FROM cs_agg
JOIN call_center cc
  ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
  ON cs_agg.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON cs_agg.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN (
    SELECT ws.ws_bill_cdemo_sk,
           AVG(ws.ws_net_paid) AS ws_avg_net_paid
    FROM web_sales ws
    WHERE ws.ws_quantity > 1
      AND ws.ws_ext_discount_amt < 300
    GROUP BY ws.ws_bill_cdemo_sk
) ws
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN (
    SELECT sr.sr_cdemo_sk,
           SUM(sr.sr_return_amt) AS sr_total_return_amt
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 0
    GROUP BY sr.sr_cdemo_sk
) sr
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
WHERE cc.cc_division IN (1, 2, 4)
  AND cc.cc_gmt_offset BETWEEN -6 AND 0
  AND cp.cp_department = 'Sports'
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
  AND ib.ib_upper_bound >= 50000
  AND cd.cd_dep_count >= 2
ORDER BY cs_agg.total_sales DESC
LIMIT 100
