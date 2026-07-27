WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cc.cc_company_name,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_net_paid,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        SUM(cs.cs_coupon_amt) AS total_catalog_coupon,
        SUM(ss.ss_coupon_amt) AS total_store_coupon,
        (SUM(cs.cs_net_paid_inc_tax) + SUM(ss.ss_net_paid)) AS total_combined_net_paid
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE cs.cs_coupon_amt > 500
      AND cs.cs_net_paid_inc_tax BETWEEN 100 AND 2000
      AND cc.cc_employees > 1000000
      AND c.c_birth_year = 1965
      AND hd.hd_vehicle_count >= 2
      AND ca.ca_state = 'CA'
      AND ss.ss_promo_sk IN (25, 368)
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cc.cc_company_name
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    ca_state,
    cc_company_name,
    total_combined_net_paid,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_combined_net_paid DESC) AS state_rank,
    DENSE_RANK() OVER (ORDER BY total_combined_net_paid DESC) AS overall_rank
FROM sales_agg
ORDER BY total_combined_net_paid DESC
LIMIT 100
