WITH sales_item AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_coupon_amt,
        cs.cs_quantity,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        i.i_item_id,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        cc.cc_division_name,
        cc.cc_state,
        cc.cc_gmt_offset
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_division_name = 'North Midwest_2'
      AND cc.cc_state = 'CA'
      AND cc.cc_gmt_offset > 0
      AND cs.cs_coupon_amt > 1000
      AND cs.cs_net_paid_inc_ship_tax BETWEEN 2000 AND 5000
      AND i.i_current_price > 50
)
SELECT
    si.cc_division_name,
    si.cc_state,
    si.i_brand,
    si.i_category,
    COUNT(DISTINCT si.cs_order_number) AS order_cnt,
    SUM(si.cs_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(si.cs_coupon_amt) AS avg_coupon_amt,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amt,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_on_hand
FROM sales_item si
LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = si.cs_order_number
   AND cr.cr_refunded_cash < 100
LEFT JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = si.cs_item_sk
   AND wr.wr_return_amt > 500
LEFT JOIN tpcds.inventory inv
    ON inv.inv_item_sk = si.cs_item_sk
GROUP BY
    si.cc_division_name,
    si.cc_state,
    si.i_brand,
    si.i_category
HAVING SUM(si.cs_net_paid_inc_ship_tax) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
