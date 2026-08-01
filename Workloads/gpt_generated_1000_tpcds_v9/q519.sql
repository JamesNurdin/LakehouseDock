SELECT *
FROM (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cp.cp_catalog_page_id AS catalog_page_id,
        SUBSTR(cp.cp_description, 1, 30) AS short_desc,
        REGEXP_EXTRACT(cp.cp_description, '(?i)service\s+(\\w+)', 1) AS service_next_word,
        cs.cs_net_paid AS net_paid,
        cs.cs_sold_date_sk AS sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.cs_net_paid DESC) AS rn
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE REGEXP_LIKE(cp.cp_description, '(?i)service')
      AND c.c_last_name LIKE 'B%'
) 
UNION
SELECT
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    CAST(NULL AS varchar) AS catalog_page_id,
    CAST(NULL AS varchar) AS short_desc,
    CAST(NULL AS varchar) AS service_next_word,
    ws.ws_net_paid AS net_paid,
    ws.ws_sold_date_sk AS sold_date_sk,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_net_paid DESC) AS rn
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
WHERE c.c_last_name LIKE 'B%'
ORDER BY net_paid DESC
LIMIT 100
