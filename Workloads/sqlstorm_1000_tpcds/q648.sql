WITH
sales_raw AS (
   SELECT cs.cs_sold_date_sk AS date_sk,
          cs.cs_bill_customer_sk AS cust_sk,
          cs.cs_net_paid AS net_paid,
          cs.cs_net_profit AS net_profit,
          cc.cc_name AS call_center_name,
          'catalog' AS channel,
          cs.cs_item_sk AS item_sk
   FROM catalog_sales cs
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk

   UNION ALL

   SELECT ss.ss_sold_date_sk,
          ss.ss_customer_sk,
          ss.ss_net_paid,
          ss.ss_net_profit,
          CAST(null AS varchar) AS call_center_name,
          'store' AS channel,
          ss.ss_item_sk
   FROM store_sales ss

   UNION ALL

   SELECT ws.ws_sold_date_sk,
          ws.ws_bill_customer_sk,
          ws.ws_net_paid,
          ws.ws_net_profit,
          CAST(null AS varchar) AS call_center_name,
          'web' AS channel,
          ws.ws_item_sk
   FROM web_sales ws
),
return_raw AS (
   SELECT cr.cr_returned_date_sk AS date_sk,
          cr.cr_returning_customer_sk AS cust_sk,
          cr.cr_net_loss AS net_loss,
          cr.cr_item_sk AS item_sk
   FROM catalog_returns cr

   UNION ALL

   SELECT sr.sr_returned_date_sk,
          sr.sr_customer_sk,
          sr.sr_net_loss,
          sr.sr_item_sk
   FROM store_returns sr

   UNION ALL

   SELECT wr.wr_returned_date_sk,
          wr.wr_returning_customer_sk,
          wr.wr_net_loss,
          wr.wr_item_sk
   FROM web_returns wr
),
sales_cum AS (
   SELECT sr.*,
          SUM(sr.net_paid) OVER (PARTITION BY sr.cust_sk ORDER BY sr.date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net_paid
   FROM sales_raw sr
),
cust_sales_agg AS (
   SELECT sc.cust_sk,
          SUM(sc.net_paid) AS total_net_paid,
          SUM(sc.net_profit) AS total_net_profit,
          COUNT(*) AS total_transactions,
          COUNT(DISTINCT sc.item_sk) AS distinct_items,
          MIN(sc.date_sk) AS first_sale_date_sk,
          MAX(sc.date_sk) AS last_sale_date_sk,
          MAX(sc.running_total_net_paid) AS final_running_total_net_paid,
          MAX(sc.call_center_name) AS call_center_name,
          MAX(CASE WHEN sc.channel = 'catalog' THEN 1 ELSE 0 END) AS has_catalog_flag
   FROM sales_cum sc
   GROUP BY sc.cust_sk
),
cust_sales_ranked AS (
   SELECT csa.*,
          RANK() OVER (ORDER BY csa.total_net_profit DESC) AS profit_rank
   FROM cust_sales_agg csa
),
cust_returns_agg AS (
   SELECT rr.cust_sk,
          SUM(rr.net_loss) AS total_net_loss,
          COUNT(*) AS total_return_transactions,
          COUNT(DISTINCT rr.item_sk) AS distinct_return_items
   FROM return_raw rr
   GROUP BY rr.cust_sk
),
combined_all AS (
   SELECT csr.cust_sk,
          csr.total_net_paid,
          csr.total_net_profit,
          csr.total_transactions,
          csr.distinct_items,
          cra.total_net_loss,
          cra.total_return_transactions,
          cra.distinct_return_items,
          csr.total_net_profit - COALESCE(cra.total_net_loss, 0) AS net_profit_after_returns,
          csr.profit_rank,
          csr.call_center_name,
          csr.has_catalog_flag,
          csr.first_sale_date_sk,
          csr.last_sale_date_sk,
          csr.final_running_total_net_paid AS running_total_net_paid,
          d_first.d_year AS first_sale_year,
          d_last.d_year AS last_sale_year,
          c.c_first_name,
          c.c_last_name,
          ca.ca_city,
          ca.ca_state,
          COALESCE(c.c_preferred_cust_flag, 'N') AS preferred_flag,
          CASE 
              WHEN csr.total_net_profit - COALESCE(cra.total_net_loss, 0) > 10000 THEN 'HIGH'
              WHEN csr.total_net_profit - COALESCE(cra.total_net_loss, 0) > 0 THEN 'MEDIUM'
              ELSE 'LOW'
          END AS profit_category,
          CONCAT(UPPER(c.c_first_name), ' ', UPPER(c.c_last_name)) AS full_name_upper
   FROM cust_sales_ranked csr
   LEFT JOIN cust_returns_agg cra ON csr.cust_sk = cra.cust_sk
   LEFT JOIN customer c ON csr.cust_sk = c.c_customer_sk
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   LEFT JOIN date_dim d_first ON csr.first_sale_date_sk = d_first.d_date_sk
   LEFT JOIN date_dim d_last ON csr.last_sale_date_sk = d_last.d_date_sk
   WHERE COALESCE(ca.ca_city, '') LIKE 'A%'
)
SELECT
   ca.full_name_upper,
   ca.profit_category,
   ca.net_profit_after_returns,
   ca.profit_rank,
   ca.total_transactions,
   ca.total_return_transactions,
   ca.distinct_items,
   ca.distinct_return_items,
   COALESCE(ca.call_center_name, 'N/A') AS call_center,
   ca.first_sale_year,
   ca.last_sale_year,
   ca.preferred_flag,
   ca.running_total_net_paid,
   (SELECT COUNT(DISTINCT s2.item_sk)
      FROM sales_raw s2
      WHERE s2.cust_sk = ca.cust_sk
        AND s2.channel = 'catalog') AS catalog_distinct_item_cnt,
   CASE
      WHEN (SELECT SUM(s2.net_paid)
            FROM sales_raw s2
            WHERE s2.cust_sk = ca.cust_sk
              AND s2.channel = 'web') > 5000 THEN 'Web-Heavy'
      ELSE 'Not Web-Heavy'
   END AS web_spend_category
FROM combined_all ca
WHERE ca.profit_rank <= 10
ORDER BY ca.profit_rank
