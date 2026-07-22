WITH combined AS (
   SELECT
       cc.cc_city,
       i.i_category,
       w.w_warehouse_name,
       sm.sm_type,
       hd.hd_buy_potential,
       ib.ib_lower_bound,
       SUM(cs.cs_net_paid_inc_tax) AS catalog_sales_net,
       SUM(ss.ss_net_paid_inc_tax) AS store_sales_net,
       SUM(COALESCE(cr.cr_return_amt_inc_tax, 0)) AS catalog_returns_amount,
       SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS store_returns_amount,
       SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS web_returns_amount
   FROM catalog_sales cs
   JOIN call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w
       ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i
       ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_demographics cd
       ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
       ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca
       ON cs.cs_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN catalog_returns cr
       ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_item_sk = i.i_item_sk
   LEFT JOIN store_sales ss
       ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN store_returns sr
       ON sr.sr_ticket_number = ss.ss_ticket_number
      AND sr.sr_item_sk = i.i_item_sk
   LEFT JOIN web_returns wr
       ON wr.wr_item_sk = i.i_item_sk
   LEFT JOIN income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE cc.cc_city = 'Spring Hill'
     AND i.i_current_price > 50
     AND hd.hd_vehicle_count > 1
     AND ib.ib_lower_bound >= 50000
   GROUP BY cc.cc_city,
            i.i_category,
            w.w_warehouse_name,
            sm.sm_type,
            hd.hd_buy_potential,
            ib.ib_lower_bound
)
SELECT
    cc_city,
    i_category,
    w_warehouse_name,
    sm_type,
    hd_buy_potential,
    ib_lower_bound,
    catalog_sales_net,
    store_sales_net,
    catalog_returns_amount,
    store_returns_amount,
    web_returns_amount,
    (catalog_sales_net + store_sales_net) - (catalog_returns_amount + store_returns_amount + web_returns_amount) AS net_margin,
    (SELECT AVG((c.catalog_sales_net + c.store_sales_net) - (c.catalog_returns_amount + c.store_returns_amount + c.web_returns_amount))
       FROM combined c) AS overall_avg_margin
FROM combined
WHERE (catalog_sales_net + store_sales_net) - (catalog_returns_amount + store_returns_amount + web_returns_amount) >
      (SELECT AVG((c.catalog_sales_net + c.store_sales_net) - (c.catalog_returns_amount + c.store_returns_amount + c.web_returns_amount))
         FROM combined c)
ORDER BY net_margin DESC
LIMIT 100
