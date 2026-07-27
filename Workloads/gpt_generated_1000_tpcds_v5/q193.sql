SELECT
    d.d_year AS year,
    cc.cc_name AS call_center_name,
    i.i_category AS item_category,
    hd.hd_buy_potential AS buy_potential,
    ws.web_name AS website,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(cs.cs_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > 0 THEN SUM(cs.cs_net_profit) / SUM(cs.cs_ext_sales_price)
        ELSE NULL
    END AS profit_margin
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN store_returns sr
  ON sr.sr_customer_sk = c.c_customer_sk
 AND sr.sr_item_sk = i.i_item_sk
 AND sr.sr_hdemo_sk = hd.hd_demo_sk
 AND sr.sr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
 AND wr.wr_item_sk = i.i_item_sk
 AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
 AND wr.wr_returned_date_sk = d.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND cc.cc_state = 'CA'
  AND i.i_category = 'Sports'
  AND hd.hd_buy_potential = '500-1000'
  AND cs.cs_coupon_amt = 0.00
GROUP BY
    d.d_year,
    cc.cc_name,
    i.i_category,
    hd.hd_buy_potential,
    ws.web_name
ORDER BY total_net_profit DESC
LIMIT 100
