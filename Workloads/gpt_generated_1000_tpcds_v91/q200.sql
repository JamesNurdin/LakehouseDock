WITH
   filtered_date AS (
       SELECT d_date_sk, d_date, d_year
       FROM date_dim
       WHERE d_year = 2001
   ),
   store_sales_agg AS (
       SELECT
           ss.ss_sold_date_sk,
           d.d_date,
           s.s_store_id,
           s.s_store_name,
           SUM(ss.ss_net_paid_inc_tax) AS store_net_paid_inc_tax,
           COUNT(*) AS store_txn_cnt,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers
       FROM store_sales ss
       JOIN filtered_date d ON ss.ss_sold_date_sk = d.d_date_sk
       JOIN store s ON ss.ss_store_sk = s.s_store_sk
       JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
       JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
       JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
       WHERE
           ca.ca_state = 'TX'
           AND cd.cd_gender = 'M'
           AND cd.cd_marital_status = 'M'
           AND hd.hd_vehicle_count > 1
           AND s.s_manager = 'John Mccoy'
       GROUP BY ss.ss_sold_date_sk, d.d_date, s.s_store_id, s.s_store_name
   ),
   catalog_sales_agg AS (
       SELECT
           cs.cs_sold_date_sk,
           d.d_date,
           SUM(cs.cs_net_paid_inc_tax) AS catalog_net_paid_inc_tax,
           COUNT(*) AS catalog_txn_cnt,
           COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_catalog_customers
       FROM catalog_sales cs
       JOIN filtered_date d ON cs.cs_sold_date_sk = d.d_date_sk
       JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
       JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
       JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
       WHERE
           ca.ca_state = 'TX'
           AND cd.cd_gender = 'M'
           AND cd.cd_marital_status = 'M'
           AND hd.hd_vehicle_count > 1
           AND EXISTS (
               SELECT 1
               FROM web_page wp
               WHERE wp.wp_creation_date_sk = d.d_date_sk
                 AND wp.wp_type = 'Home'
           )
       GROUP BY cs.cs_sold_date_sk, d.d_date
   ),
   combined AS (
       SELECT
           COALESCE(s.d_date, c.d_date) AS sale_date,
           COALESCE(s.s_store_id, 'ONLINE') AS store_id,
           COALESCE(s.s_store_name, 'Catalog') AS store_name,
           COALESCE(s.store_net_paid_inc_tax, 0) + COALESCE(c.catalog_net_paid_inc_tax, 0) AS total_net_paid_inc_tax,
           COALESCE(s.store_txn_cnt, 0) + COALESCE(c.catalog_txn_cnt, 0) AS total_txn_cnt,
           COALESCE(s.distinct_store_customers, 0) + COALESCE(c.distinct_catalog_customers, 0) AS total_distinct_customers
       FROM store_sales_agg s
       FULL OUTER JOIN catalog_sales_agg c
           ON s.d_date = c.d_date
   )
SELECT
    sale_date,
    store_id,
    store_name,
    total_net_paid_inc_tax,
    total_txn_cnt,
    total_distinct_customers,
    RANK() OVER (ORDER BY total_net_paid_inc_tax DESC) AS revenue_rank
FROM combined
WHERE total_txn_cnt > 0
ORDER BY revenue_rank
LIMIT 100
