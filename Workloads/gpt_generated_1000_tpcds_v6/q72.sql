WITH grouped AS (
   SELECT
       s.s_store_id,
       s.s_market_manager,
       cp.cp_department,
       r_cat.r_reason_desc AS catalog_return_reason,
       r_web.r_reason_desc AS web_return_reason,
       c.c_customer_id,
       cd.cd_gender,
       hd.hd_income_band_sk,
       SUM(ss.ss_ext_sales_price) AS total_store_sales,
       SUM(ws.ws_ext_sales_price) AS total_web_sales,
       SUM(cr.cr_return_amount) AS total_catalog_return_amount,
       SUM(wr.wr_return_amt) AS total_web_return_amount,
       COUNT(*) AS txn_count,
       AVG(ss.ss_quantity) AS avg_store_quantity,
       MIN(ss.ss_ext_sales_price) AS min_store_sale,
       MAX(ss.ss_ext_sales_price) AS max_store_sale
   FROM store s
   JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN reason r_cat ON cr.cr_reason_sk = r_cat.r_reason_sk
   JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
   JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
   WHERE s.s_market_manager = 'Thomas Pollack'
     AND cp.cp_department = 'Sports'
     AND r_cat.r_reason_desc = 'Package was damaged'
     AND r_web.r_reason_desc = 'Did not like the color'
     AND ca.ca_state = 'CA'
     AND NOT EXISTS (
         SELECT 1
         FROM catalog_returns cr2
         WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
           AND cr2.cr_reason_sk <> cr.cr_reason_sk
     )
   GROUP BY
       s.s_store_id,
       s.s_market_manager,
       cp.cp_department,
       r_cat.r_reason_desc,
       r_web.r_reason_desc,
       c.c_customer_id,
       cd.cd_gender,
       hd.hd_income_band_sk
   HAVING SUM(ss.ss_ext_sales_price) > 10000
      AND COUNT(*) >= 5
)
SELECT
    g.*,
    RANK() OVER (PARTITION BY g.s_market_manager ORDER BY g.total_store_sales DESC) AS sales_rank,
    SUM(g.total_store_sales) OVER (PARTITION BY g.s_market_manager) AS market_total_store_sales
FROM grouped g
ORDER BY g.total_store_sales DESC
LIMIT 100
