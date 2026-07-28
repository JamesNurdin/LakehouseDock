WITH sales_base AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_quantity,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
)
SELECT
    cc.cc_company_name,
    cp.cp_department,
    t.t_hour,
    CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_quantity) AS avg_quantity,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS active_promo_cnt
FROM sales_base cs
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = t.t_time_sk
GROUP BY
    cc.cc_company_name,
    cp.cp_department,
    t.t_hour,
    CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END
ORDER BY total_sales DESC
LIMIT 100
