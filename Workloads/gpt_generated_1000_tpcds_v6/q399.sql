SELECT
    sm.sm_ship_mode_id,
    d.d_year,
    ca.ca_state,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    AVG(ss.ss_net_profit) AS avg_store_net_profit,
    MIN(cs.cs_ext_discount_amt) AS min_discount,
    MAX(cs.cs_ext_sales_price) AS max_sales_price
FROM
    ship_mode sm
    JOIN catalog_sales cs
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer c
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND sm.sm_contract = 'fop0bcSd91J26IVpR'
    AND wp.wp_max_ad_count >= 2
    AND ca.ca_state = 'CA'
    AND cs.cs_quantity > 5
GROUP BY
    sm.sm_ship_mode_id,
    d.d_year,
    ca.ca_state
ORDER BY
    total_catalog_sales DESC
LIMIT 100
