WITH avg_cc_return AS (
    SELECT
        cr.cr_call_center_sk,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_call_center_sk
)
SELECT
    d.d_year,
    cc.cc_name,
    cp.cp_catalog_page_number,
    cd_refunded.cd_gender,
    hd_refunded.hd_dep_count,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ws.ws_wholesale_cost) AS avg_wholesale_cost,
    MIN(ws.ws_ext_sales_price) AS min_sales_price,
    MAX(ws.ws_ext_sales_price) AS max_sales_price,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(CASE WHEN cr.cr_return_amount > avg_rc.avg_return_amount THEN 1 ELSE 0 END) AS above_avg_return_count,
    SUM(CASE WHEN ws.ws_net_profit > 0 THEN 1 ELSE 0 END) AS profit_orders_count,
    (SELECT MAX(d2.d_year) FROM date_dim d2) AS max_year
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN avg_cc_return avg_rc ON avg_rc.cr_call_center_sk = cc.cc_call_center_sk
WHERE d.d_year = 2001
  AND cc.cc_state = 'CA'
  AND cp.cp_catalog_page_number IN (2, 15, 13)
  AND cd_refunded.cd_gender = 'F'
  AND hd_refunded.hd_dep_count > 5
  AND ws.ws_wholesale_cost > 20.0
  AND i.inv_quantity_on_hand > 0
  AND cr.cr_return_amount > 100.0
GROUP BY d.d_year, cc.cc_name, cp.cp_catalog_page_number, cd_refunded.cd_gender, hd_refunded.hd_dep_count
ORDER BY total_return_amount DESC
LIMIT 100
