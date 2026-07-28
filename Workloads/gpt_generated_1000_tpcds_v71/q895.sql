WITH promo_union AS (
    SELECT cs.cs_promo_sk AS promo_sk FROM catalog_sales cs
    UNION
    SELECT ws.ws_promo_sk FROM web_sales ws
),
filtered_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_birth_country = 'United States'
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1950 AND 1960
)
SELECT
    c.c_customer_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_count,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    CASE
        WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High'
        WHEN SUM(ss.ss_net_paid) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS store_sales_category,
    (SELECT COUNT(*) FROM promo_union) AS total_distinct_promos,
    (SELECT AVG(cs.cs_ext_discount_amt)
       FROM catalog_sales cs
       WHERE cs.cs_promo_sk IN (SELECT promo_sk FROM promo_union)) AS avg_catalog_discount
FROM
    store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE
    p.p_discount_active = 'Y'
    AND ca.ca_state = 'CA'
    AND wsite.web_country = 'United States'
    AND cs.cs_quantity > 2
GROUP BY
    c.c_customer_id
HAVING
    COUNT(DISTINCT ss.ss_ticket_number) > 5
ORDER BY
    total_store_sales DESC
LIMIT 100
