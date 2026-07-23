WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
)
SELECT
    cc.cc_name AS call_center_name,
    cp.cp_department AS department,
    i.i_category AS item_category,
    c_bill.c_customer_id AS billing_customer_id,
    p.p_promo_name AS promo_name,
    COUNT(DISTINCT s.cs_order_number) AS order_count,
    SUM(s.cs_ext_sales_price) AS total_sales,
    AVG(s.cs_net_profit) AS avg_profit,
    SUM(CASE WHEN s.cs_net_profit > 100 THEN s.cs_ext_sales_price ELSE 0 END) AS high_profit_sales,
    MIN(s.cs_ext_sales_price) AS min_sales,
    MAX(s.cs_ext_sales_price) AS max_sales
FROM sales s
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c_bill ON s.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON s.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill ON s.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON s.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill ON s.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON s.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
WHERE
    c_bill.c_preferred_cust_flag = 'Y'
    AND c_bill.c_birth_day = 8
    AND cd_bill.cd_dep_employed_count >= 3
    AND p.p_cost > 100.00
    AND cc.cc_state = 'CA'
GROUP BY
    cc.cc_name,
    cp.cp_department,
    i.i_category,
    c_bill.c_customer_id,
    p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
