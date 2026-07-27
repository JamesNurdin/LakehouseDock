WITH base_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_addr_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1500
      AND cs.cs_quantity >= 2
      AND cs.cs_ext_discount_amt < 200
)
SELECT
    cc.cc_name               AS call_center_name,
    sm.sm_type               AS ship_mode_type,
    i.i_category             AS item_category,
    ib.ib_lower_bound        AS income_lower,
    ib.ib_upper_bound        AS income_upper,
    COUNT(DISTINCT base.cs_order_number) AS order_cnt,
    SUM(base.cs_ext_sales_price)          AS total_catalog_sales,
    SUM(sr.sr_return_amt)                 AS total_store_returns,
    SUM(ws.ws_ext_sales_price)            AS total_web_sales,
    AVG(base.cs_ext_discount_amt)         AS avg_discount,
    SUM(base.cs_net_profit)               AS total_net_profit
FROM base_sales base
JOIN call_center cc
    ON base.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON base.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON base.cs_item_sk = i.i_item_sk
JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
JOIN household_demographics hd
    ON base.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_demographics cd
    ON base.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON base.cs_bill_addr_sk = ca.ca_address_sk
JOIN store_returns sr
    ON i.i_item_sk = sr.sr_item_sk
JOIN web_sales ws
    ON i.i_item_sk = ws.ws_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site webs
    ON ws.ws_web_site_sk = webs.web_site_sk
JOIN web_returns wr
    ON i.i_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
WHERE ib.ib_lower_bound = 50001
  AND webs.web_state = 'CA'
GROUP BY
    cc.cc_name,
    sm.sm_type,
    i.i_category,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING SUM(base.cs_ext_sales_price) > 50000
ORDER BY total_catalog_sales DESC
LIMIT 100
