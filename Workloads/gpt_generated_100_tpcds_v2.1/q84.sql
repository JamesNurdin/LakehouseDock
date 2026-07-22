WITH
    d_date AS (
        SELECT * FROM date_dim
    ),
    t_time AS (
        SELECT * FROM time_dim
    )
SELECT
    cc.cc_name AS call_center_name,
    d_date.d_year AS year,
    CASE WHEN d_date.d_year >= 2000 THEN '21st Century' ELSE '20th Century' END AS century_flag,
    r.r_reason_desc AS return_reason,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(cs.cs_quantity) + SUM(ws.ws_quantity) + SUM(sr.sr_return_quantity) AS total_quantity,
    SUM(CASE WHEN cs.cs_quantity > 10 THEN cs.cs_ext_sales_price ELSE 0 END) AS large_quantity_sales,
    COUNT(DISTINCT r.r_reason_desc) AS distinct_return_reasons
FROM catalog_sales cs
JOIN d_date ON cs.cs_sold_date_sk = d_date.d_date_sk
JOIN t_time ON cs.cs_sold_time_sk = t_time.t_time_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib_ship ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_date.d_date_sk
JOIN time_dim t_sr_time ON sr.sr_return_time_sk = t_sr_time.t_time_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN income_band ib_sr ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_date.d_date_sk
JOIN time_dim t_ws_time ON ws.ws_sold_time_sk = t_ws_time.t_time_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN income_band ib_ws_bill ON hd_ws_bill.hd_income_band_sk = ib_ws_bill.ib_income_band_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN income_band ib_ws_ship ON hd_ws_ship.hd_income_band_sk = ib_ws_ship.ib_income_band_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d_date.d_year BETWEEN 1999 AND 2002
GROUP BY
    cc.cc_name,
    d_date.d_year,
    CASE WHEN d_date.d_year >= 2000 THEN '21st Century' ELSE '20th Century' END,
    r.r_reason_desc
ORDER BY total_catalog_profit DESC
LIMIT 100
