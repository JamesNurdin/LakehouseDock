WITH avg_catalog AS (
    SELECT avg(cs_net_paid_inc_tax) AS avg_net_paid
    FROM catalog_sales
)
SELECT
    ca.ca_zip AS zip_code,
    'catalog' AS sales_source,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax
FROM catalog_sales cs
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE cs.cs_net_paid_inc_tax > 500
  AND ca.ca_state = 'TX'
  AND cs.cs_net_paid_inc_tax > (SELECT avg_net_paid FROM avg_catalog)
GROUP BY ca.ca_zip

UNION ALL

SELECT
    ca.ca_zip AS zip_code,
    'store' AS sales_source,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax
FROM store_sales ss
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
WHERE ss.ss_net_paid_inc_tax > 500
  AND ca.ca_state = 'TX'
  AND ss.ss_net_paid_inc_tax > (SELECT avg_net_paid FROM avg_catalog)
GROUP BY ca.ca_zip

ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
