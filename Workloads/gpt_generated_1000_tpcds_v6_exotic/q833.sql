WITH email_customers AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_email_address,
        regexp_extract(c_email_address, '@([^.]*)\\.', 1) AS domain_part
    FROM tpcds.customer
    WHERE c_email_address LIKE '%@example.com'
      AND c_first_name LIKE 'J%'
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT ec.c_customer_sk) AS cust_cnt,
    MIN(cs.cs_sold_date_sk) AS first_sale_date_sk,
    MAX(cs.cs_sold_date_sk) AS last_sale_date_sk
FROM email_customers ec
JOIN tpcds.catalog_sales cs
    ON cs.cs_bill_customer_sk = ec.c_customer_sk
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE regexp_like(cp.cp_description, '(?i)electronics|furniture')
  AND cp.cp_type LIKE 'C_%'
  AND regexp_like(cc.cc_name, '^\\w+ Center$')
  AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_page cp2
        WHERE cp2.cp_catalog_page_sk = cp.cp_catalog_page_sk
          AND cp2.cp_type = 'A'
    )
GROUP BY cc.cc_call_center_id, cc.cc_name
HAVING SUM(cs.cs_net_profit) > (
        SELECT AVG(sub_profit) FROM (
            SELECT SUM(cs2.cs_net_profit) AS sub_profit
            FROM tpcds.catalog_sales cs2
            JOIN tpcds.call_center cc2
                ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
            GROUP BY cc2.cc_call_center_id
        ) t
    )
ORDER BY total_profit DESC
LIMIT 100
