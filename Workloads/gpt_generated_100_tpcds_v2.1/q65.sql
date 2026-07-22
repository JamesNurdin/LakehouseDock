WITH sales_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_sold_time_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_quantity > 5
      AND ws.ws_sales_price > 20
      AND ws.ws_net_profit > 0
      AND wsit.web_city = 'Pine Grove'
      AND td.t_hour BETWEEN 9 AND 17
      AND hd.hd_vehicle_count >= 2
    GROUP BY ws.ws_warehouse_sk, ws.ws_sold_time_sk, ws.ws_web_site_sk
),
return_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_returned_time_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_warehouse_sk, cr.cr_returned_time_sk
)
SELECT
    w.w_warehouse_name,
    wsit.web_city,
    td.t_hour,
    ss.total_sales,
    ss.avg_sales_price,
    ss.order_cnt,
    ss.total_profit,
    ra.total_return_amount,
    ra.return_cnt,
    c.c_last_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    inv.inv_quantity_on_hand,
    (
        SELECT MAX(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
          AND cr2.cr_returned_time_sk = td.t_time_sk
    ) AS max_return_amount
FROM sales_agg ss
JOIN warehouse w ON ss.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td ON ss.ws_sold_time_sk = td.t_time_sk
JOIN web_site wsit ON ss.ws_web_site_sk = wsit.web_site_sk
JOIN catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
    AND cr.cr_returned_time_sk = td.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN return_agg ra ON ra.cr_warehouse_sk = w.w_warehouse_sk
    AND ra.cr_returned_time_sk = td.t_time_sk
WHERE cc.cc_state = 'CA'
  AND cp.cp_department = 'Sports'
  AND ib.ib_lower_bound >= 50000
  AND inv.inv_quantity_on_hand > 100
  AND wsit.web_suite_number = 'Suite 370 '
  AND c.c_birth_month = 12
ORDER BY ss.total_sales DESC
LIMIT 100
