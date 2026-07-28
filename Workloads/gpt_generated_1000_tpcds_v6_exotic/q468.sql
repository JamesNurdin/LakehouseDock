WITH promo_union AS (
    SELECT p_promo_sk, p_promo_name, p_discount_active
    FROM promotion
    WHERE p_discount_active = 'Y'
    UNION
    SELECT p_promo_sk, p_promo_name, p_discount_active
    FROM promotion
    WHERE p_channel_tv = 'Y'
)
SELECT
    s.s_state,
    pu.p_promo_name,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(
        (SELECT AVG(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
         WHERE cs2.cs_promo_sk = cs.cs_promo_sk)
    ) AS avg_catalog_sales_per_promo
FROM catalog_sales cs
JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_demographics cdm_bill ON cs.cs_bill_cdemo_sk = cdm_bill.cd_demo_sk
JOIN household_demographics hdm_bill ON cs.cs_bill_hdemo_sk = hdm_bill.hd_demo_sk
JOIN customer_address addr_bill ON cs.cs_bill_addr_sk = addr_bill.ca_address_sk
JOIN promo_union pu ON cs.cs_promo_sk = pu.p_promo_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss ON ss.ss_customer_sk = cust_bill.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion promo_ss ON ss.ss_promo_sk = promo_ss.p_promo_sk
JOIN customer_demographics cdm_ss ON ss.ss_cdemo_sk = cdm_ss.cd_demo_sk
JOIN household_demographics hdm_ss ON ss.ss_hdemo_sk = hdm_ss.hd_demo_sk
JOIN customer_address addr_ss ON ss.ss_addr_sk = addr_ss.ca_address_sk
WHERE s.s_state = 'CA'
GROUP BY s.s_state, pu.p_promo_name
HAVING SUM(cs.cs_net_paid) > 100000
ORDER BY total_catalog_net_paid DESC
LIMIT 100
