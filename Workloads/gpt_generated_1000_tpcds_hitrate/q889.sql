WITH distinct_promos AS (
    SELECT DISTINCT p_promo_sk, p_promo_name
    FROM promotion
),
sales AS (
    SELECT *
    FROM catalog_sales
),
returns AS (
    SELECT *
    FROM catalog_returns
)
SELECT
    cc.cc_name,
    cp.cp_department,
    dp.p_promo_name,
    sm.sm_carrier,
    w.w_warehouse_name,
    s.s_store_name,
    CASE
        WHEN COALESCE(sales.cs_net_profit, 0) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_flag,
    SUM(COALESCE(sales.cs_net_paid, 0) - COALESCE(returns.cr_return_amount, 0)) AS total_net_amount
FROM sales
FULL OUTER JOIN returns
    ON sales.cs_order_number = returns.cr_order_number
JOIN call_center cc
    ON sales.cs_call_center_sk = cc.cc_call_center_sk
JOIN distinct_promos dp
    ON sales.cs_promo_sk = dp.p_promo_sk
JOIN catalog_page cp
    ON sales.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON sales.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON sales.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c_bill
    ON sales.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON sales.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer c_refund
    ON returns.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c_bill.c_customer_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
WHERE
    sales.cs_quantity > (SELECT MAX(cs_quantity) FROM catalog_sales WHERE cs_sold_date_sk = 20000101)
    AND cc.cc_tax_percentage > (SELECT AVG(cc_tax_percentage) FROM call_center)
GROUP BY
    cc.cc_name,
    cp.cp_department,
    dp.p_promo_name,
    sm.sm_carrier,
    w.w_warehouse_name,
    s.s_store_name,
    CASE
        WHEN COALESCE(sales.cs_net_profit, 0) > 0 THEN 'Profit'
        ELSE 'Loss'
    END
ORDER BY total_net_amount DESC
LIMIT 100
