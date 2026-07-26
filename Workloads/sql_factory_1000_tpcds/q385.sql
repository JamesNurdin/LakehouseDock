WITH profit_by_cc AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_employees,
        cc.cc_city,
        cc.cc_state,
        MAX(ca_bill.ca_city) AS billing_city,
        SUM(cs.cs_net_profit - cs.cs_ext_discount_amt - COALESCE(p.p_cost, 0)) AS total_adjusted_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_employees,
        cc.cc_city,
        cc.cc_state
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_city,
    cc_state,
    billing_city,
    total_adjusted_profit,
    total_sales,
    ROUND(total_adjusted_profit / NULLIF(total_sales, 0), 4) AS profit_margin,
    CASE
        WHEN cc_employees >= 500 THEN 'Large'
        WHEN cc_employees >= 200 THEN 'Medium'
        ELSE 'Small'
    END AS size_category,
    DENSE_RANK() OVER (ORDER BY total_adjusted_profit DESC) AS profit_rank
FROM profit_by_cc
ORDER BY profit_rank
LIMIT 5
