SELECT
    d.d_year AS year,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_quantity > (
        SELECT MAX(cs_quantity)
        FROM catalog_sales
        WHERE cs_sold_date_sk = 2450816
    )
  AND cp.cp_department = 'Books'
  AND d.d_year BETWEEN 2001 AND 2002
UNION
SELECT
    d.d_year AS year,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE ss.ss_quantity > (
        SELECT AVG(ss_quantity)
        FROM store_sales
    )
  AND s.s_state = 'CA'
  AND ss.ss_store_sk IN (
        SELECT s_store_sk
        FROM store
        WHERE s_state = 'CA'
    )
  AND d.d_year BETWEEN 2001 AND 2002
LIMIT 100
