WITH
sales_union AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_bill_customer_sk AS cust_sk,
         cs.cs_order_number AS order_number,
         cs.cs_quantity AS quantity,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_customer_sk,
         ss.ss_ticket_number,
         ss.ss_quantity,
         ss.ss_net_paid,
         ss.ss_net_profit,
         'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_bill_customer_sk,
         ws.ws_order_number,
         ws.ws_quantity,
         ws.ws_net_paid,
         ws.ws_net_profit,
         'web' AS channel
  FROM web_sales ws
),
returns_union AS (
  SELECT cr.cr_returned_date_sk AS date_sk,
         cr.cr_returning_customer_sk AS cust_sk,
         cr.cr_order_number AS order_number,
         cr.cr_return_quantity AS return_quantity,
         cr.cr_net_loss AS net_loss,
         'catalog' AS channel
  FROM catalog_returns cr
  UNION ALL
  SELECT sr.sr_returned_date_sk,
         sr.sr_customer_sk,
         sr.sr_ticket_number,
         sr.sr_return_quantity,
         sr.sr_net_loss,
         'store' AS channel
  FROM store_returns sr
  UNION ALL
  SELECT wr.wr_returned_date_sk,
         wr.wr_refunded_customer_sk,
         wr.wr_order_number,
         wr.wr_return_quantity,
         wr.wr_net_loss,
         'web' AS channel
  FROM web_returns wr
),
full_sales_returns AS (
  SELECT COALESCE(su.cust_sk, ru.cust_sk) AS cust_sk,
         COALESCE(su.order_number, ru.order_number) AS order_number,
         COALESCE(su.date_sk, ru.date_sk) AS date_sk,
         su.channel AS sales_channel,
         ru.channel AS return_channel,
         su.net_paid,
         ru.net_loss,
         su.quantity,
         ru.return_quantity,
         su.net_profit,
         CASE WHEN su.cust_sk IS NULL THEN 'NoSales' ELSE 'HasSales' END AS sales_flag,
         CASE WHEN ru.cust_sk IS NULL THEN 'NoReturns' ELSE 'HasReturns' END AS return_flag
  FROM sales_union su
  FULL OUTER JOIN returns_union ru
    ON su.cust_sk = ru.cust_sk AND su.order_number = ru.order_number
),
sales_agg AS (
  SELECT fsr.cust_sk,
         COUNT(DISTINCT fsr.order_number) AS order_count,
         SUM(COALESCE(fsr.net_paid, 0)) AS total_net_paid,
         SUM(COALESCE(fsr.net_profit, 0)) AS total_net_profit,
         SUM(COALESCE(fsr.quantity, 0)) AS total_quantity,
         SUM(CASE WHEN fsr.net_paid = 0 THEN 0 ELSE fsr.net_profit / NULLIF(fsr.net_paid, 0) END) AS avg_profit_margin,
         MIN(d.d_year) AS first_year,
         MAX(d.d_year) AS last_year
  FROM full_sales_returns fsr
  LEFT JOIN date_dim d ON fsr.date_sk = d.d_date_sk
  GROUP BY fsr.cust_sk
),
returns_agg AS (
  SELECT ru.cust_sk,
         COUNT(*) AS return_count,
         SUM(ru.net_loss) AS total_return_loss,
         COUNT(CASE WHEN ru.channel = 'web' THEN 1 END) AS web_returns,
         COUNT(CASE WHEN ru.channel = 'store' THEN 1 END) AS store_returns,
         COUNT(CASE WHEN ru.channel = 'catalog' THEN 1 END) AS catalog_returns
  FROM returns_union ru
  GROUP BY ru.cust_sk
),
final AS (
  SELECT sa.cust_sk,
         CONCAT('CUST_', COALESCE(CAST(sa.cust_sk AS VARCHAR), 'NULL')) AS cust_key,
         sa.first_year,
         sa.last_year,
         sa.order_count,
         sa.total_net_paid,
         sa.total_net_profit,
         CASE
           WHEN sa.total_net_paid IS NULL OR sa.total_net_paid = 0 THEN NULL
           ELSE sa.total_net_profit / sa.total_net_paid
         END AS overall_profit_margin,
         COALESCE(ra.return_count, 0) AS return_count,
         COALESCE(ra.total_return_loss, 0) AS total_return_loss,
         COALESCE(ra.web_returns, 0) AS web_returns,
         COALESCE(ra.store_returns, 0) AS store_returns,
         COALESCE(ra.catalog_returns, 0) AS catalog_returns,
         CASE
           WHEN COALESCE(ra.return_count, 0) = 0 THEN 'No Returns'
           WHEN COALESCE(ra.return_count, 0) > sa.order_count THEN 'Excess Returns'
           ELSE 'Normal'
         END AS return_status,
         CASE
           WHEN LOWER(CONCAT('CUST_', COALESCE(CAST(sa.cust_sk AS VARCHAR), 'NULL'))) LIKE '%null%' THEN 'Missing ID'
           WHEN CONCAT('CUST_', COALESCE(CAST(sa.cust_sk AS VARCHAR), 'NULL')) LIKE 'CUST_%' THEN 'Valid ID'
           ELSE 'Unexpected'
         END AS id_classification,
         COALESCE(NULLIF(
           CASE
             WHEN sa.total_net_paid IS NULL OR sa.total_net_paid = 0 THEN NULL
             ELSE sa.total_net_profit / sa.total_net_paid
           END, 0), -1) AS profit_margin_coalesced,
         ROW_NUMBER() OVER (ORDER BY sa.total_net_paid DESC NULLS LAST) AS rn
  FROM sales_agg sa
  LEFT JOIN returns_agg ra ON sa.cust_sk = ra.cust_sk
)
SELECT f.cust_sk,
       f.cust_key,
       f.first_year,
       f.last_year,
       f.order_count,
       f.total_net_paid,
       f.total_net_profit,
       f.overall_profit_margin,
       f.return_count,
       f.total_return_loss,
       f.web_returns,
       f.store_returns,
       f.catalog_returns,
       f.return_status,
       f.id_classification,
       f.profit_margin_coalesced,
       cu.c_first_name,
       cu.c_last_name,
       CONCAT(COALESCE(cu.c_first_name, ''), ' ', COALESCE(cu.c_last_name, '')) AS full_name,
       ca.ca_city,
       ca.ca_state,
       (SELECT MAX(d.d_date)
          FROM date_dim d
          JOIN sales_union su2 ON su2.date_sk = d.d_date_sk
         WHERE su2.cust_sk = f.cust_sk) AS last_sale_date,
       (SELECT COUNT(*)
          FROM returns_union ru2
         WHERE ru2.cust_sk = f.cust_sk AND ru2.channel = 'web') AS web_return_count
FROM final f
LEFT JOIN customer cu ON cu.c_customer_sk = f.cust_sk
LEFT JOIN customer_address ca ON cu.c_current_addr_sk = ca.ca_address_sk
WHERE f.rn <= 20
ORDER BY f.total_net_paid DESC NULLS LAST
LIMIT 10
