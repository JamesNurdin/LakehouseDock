WITH fiscal_dates AS (
   SELECT d_date_sk
   FROM date_dim
   WHERE d_fy_year = 1919
),
ca_page_elec AS (
   SELECT cp_catalog_page_sk
   FROM catalog_page
   WHERE cp_type = 'electronics'
)
SELECT
   s.s_store_name,
   SUM(ss.ss_net_paid) AS total_net_paid,
   'store_sales' AS source
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN fiscal_dates fd ON ss.ss_sold_date_sk = fd.d_date_sk
WHERE ss.ss_store_sk IN (SELECT s_store_sk FROM store WHERE s_state = 'CA')
GROUP BY s.s_store_name

UNION ALL

SELECT
   cp.cp_description,
   SUM(cs.cs_net_paid) AS total_net_paid,
   'catalog_sales' AS source
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN fiscal_dates fd ON cs.cs_sold_date_sk = fd.d_date_sk
WHERE cs.cs_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM ca_page_elec)
GROUP BY cp.cp_description

LIMIT 100
