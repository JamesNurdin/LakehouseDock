WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 2
      AND cs.cs_net_paid > 100
      AND cs.cs_net_profit > (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2)
)
SELECT
    cp.cp_department,
    sm.sm_type,
    td.t_hour,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_cnt,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    MIN(fs.cs_sold_date_sk) AS first_sale_date_sk,
    MAX(fs.cs_sold_date_sk) AS last_sale_date_sk
FROM filtered_sales fs
JOIN catalog_page cp
    ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td
    ON fs.cs_sold_time_sk = td.t_time_sk
JOIN ship_mode sm
    ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c
    ON fs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON fs.cs_bill_addr_sk = ca.ca_address_sk
WHERE cp.cp_department = 'Electronics'
  AND cp.cp_type = 'Catalog'
  AND td.t_hour BETWEEN 9 AND 17
  AND ca.ca_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND c.c_birth_country = 'United States'
GROUP BY
    cp.cp_department,
    sm.sm_type,
    td.t_hour
ORDER BY total_net_paid DESC
LIMIT 100
