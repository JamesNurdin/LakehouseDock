WITH address_discount AS (
    SELECT
        ca_bill.ca_address_sk,
        ca_bill.ca_city,
        ca_bill.ca_state,
        MAX(cc.cc_name) AS call_center_name,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_promo_cnt
    FROM catalog_sales cs
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY ca_bill.ca_address_sk, ca_bill.ca_city, ca_bill.ca_state
)
SELECT
    ca_address_sk,
    ca_city,
    ca_state,
    call_center_name,
    total_discount,
    total_sales,
    total_net_profit,
    ROUND(total_discount / NULLIF(total_sales, 0), 4) AS discount_ratio,
    CASE
        WHEN total_discount / NULLIF(total_sales, 0) < 0.05 THEN 'Low'
        WHEN total_discount / NULLIF(total_sales, 0) < 0.15 THEN 'Medium'
        ELSE 'High'
    END AS discount_category,
    RANK() OVER (ORDER BY total_discount / NULLIF(total_sales, 0) DESC) AS discount_rank,
    LAG(ROUND(total_discount / NULLIF(total_sales, 0), 4)) OVER (ORDER BY total_discount / NULLIF(total_sales, 0) DESC) AS prev_discount_ratio
FROM address_discount
ORDER BY discount_rank
LIMIT 10
