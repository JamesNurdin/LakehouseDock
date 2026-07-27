WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_item_sk
    FROM catalog_sales cs
)
SELECT
    d_sold.d_year,
    cc.cc_name,
    sm.sm_type,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
    SUM(s.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cc_ret.cc_name) AS distinct_return_call_centers,
    AVG(s.cs_net_paid) AS avg_net_paid,
    (
        SELECT AVG(cs2.cs_net_paid)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d_sold.d_year
    ) AS year_avg_net_paid
FROM sales_data s
JOIN date_dim d_sold ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON s.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd_bill ON s.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON s.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN catalog_returns cr ON cr.cr_order_number = s.cs_order_number
JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN inventory inv ON inv.inv_date_sk = d_ship.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2001
  AND cc.cc_tax_percentage > 0.05
GROUP BY d_sold.d_year, cc.cc_name, sm.sm_type
ORDER BY total_net_paid DESC
LIMIT 100
