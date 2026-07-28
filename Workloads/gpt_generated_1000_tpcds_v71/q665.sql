WITH avg_price_per_item AS (
    SELECT cs_item_sk, avg(cs_sales_price) AS avg_price
    FROM tpcds.catalog_sales
    GROUP BY cs_item_sk
)
SELECT
    d.d_year,
    cd.cd_gender,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(CASE WHEN cs.cs_quantity > 5 THEN cs.cs_ext_sales_price ELSE 0 END) AS bulk_sales,
    AVG(cs.cs_sales_price) AS avg_individual_price,
    AVG(ap.avg_price) AS avg_item_price_across_all,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    CASE
        WHEN REGEXP_LIKE(c.c_email_address, '.*@example\\.com$') THEN 'ExampleDomain'
        WHEN REGEXP_LIKE(c.c_email_address, '.*@test\\.org$') THEN 'TestOrg'
        ELSE 'Other'
    END AS email_domain_group,
    (SELECT w.w_warehouse_name
     FROM tpcds.warehouse w
     WHERE w.w_warehouse_sk = cs.cs_warehouse_sk) AS warehouse_name
FROM tpcds.catalog_sales cs
JOIN tpcds.date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN tpcds.web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN avg_price_per_item ap
  ON cs.cs_item_sk = ap.cs_item_sk
WHERE d.d_year = 2002
  AND ca.ca_street_type LIKE 'Ave%'
  AND REGEXP_LIKE(ca.ca_address_id, '^A{5,}E')
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
          AND sr.sr_return_amt > 100
      )
GROUP BY
    d.d_year,
    cd.cd_gender,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1),
    CASE
        WHEN REGEXP_LIKE(c.c_email_address, '.*@example\\.com$') THEN 'ExampleDomain'
        WHEN REGEXP_LIKE(c.c_email_address, '.*@test\\.org$') THEN 'TestOrg'
        ELSE 'Other'
    END,
    (SELECT w.w_warehouse_name
     FROM tpcds.warehouse w
     WHERE w.w_warehouse_sk = cs.cs_warehouse_sk)
HAVING COUNT(*) > 10
ORDER BY total_sales DESC
LIMIT 100
