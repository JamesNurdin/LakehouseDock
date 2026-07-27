SELECT
    cc.cc_name,
    ib.ib_income_band_sk,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    (
        SELECT AVG(cr3.cr_return_amount)
        FROM catalog_returns cr3
        JOIN household_demographics hd3
          ON cr3.cr_refunded_hdemo_sk = hd3.hd_demo_sk
        WHERE hd3.hd_income_band_sk = ib.ib_income_band_sk
    ) AS avg_return_amount_by_income
FROM catalog_returns cr
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer cust_refunded
  ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN household_demographics hd_refunded
  ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN customer cust_bill
  ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY GROUPING SETS (
    (cc.cc_name, ib.ib_income_band_sk),
    (cc.cc_name),
    (ib.ib_income_band_sk),
    ()
)
LIMIT 100
