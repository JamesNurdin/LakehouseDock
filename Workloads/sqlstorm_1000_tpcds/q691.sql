WITH
  date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
  ),
  cust_base AS (
    SELECT
      c_customer_sk AS cust_sk,
      c_customer_id,
      COALESCE(c_first_name, '') || ' ' || COALESCE(c_last_name, '') AS full_name
    FROM customer
  ),
  catalog_agg AS (
    SELECT
      cs_bill_customer_sk AS cust_sk,
      SUM(cs_net_profit) AS catalog_net_profit,
      SUM(cs_net_paid) AS catalog_sales,
      COUNT(*) AS catalog_orders,
      MAX(cs_sold_date_sk) AS latest_catalog_date_sk
    FROM catalog_sales cs
    JOIN date_filter df ON cs.cs_sold_date_sk = df.d_date_sk
    GROUP BY cs_bill_customer_sk
  ),
  catalog_ret_agg AS (
    SELECT
      cr_returning_customer_sk AS cust_sk,
      SUM(cr_net_loss) AS catalog_net_loss,
      MAX(cr_returned_date_sk) AS latest_catalog_return_date_sk
    FROM catalog_returns cr
    JOIN date_filter df ON cr.cr_returned_date_sk = df.d_date_sk
    GROUP BY cr_returning_customer_sk
  ),
  store_agg AS (
    SELECT
      ss_customer_sk AS cust_sk,
      SUM(ss_net_profit) AS store_net_profit,
      SUM(ss_net_paid) AS store_sales,
      COUNT(*) AS store_orders,
      MAX(ss_sold_date_sk) AS latest_store_date_sk
    FROM store_sales ss
    JOIN date_filter df ON ss.ss_sold_date_sk = df.d_date_sk
    GROUP BY ss_customer_sk
  ),
  store_ret_agg AS (
    SELECT
      sr_customer_sk AS cust_sk,
      SUM(sr_net_loss) AS store_net_loss,
      MAX(sr_returned_date_sk) AS latest_store_return_date_sk
    FROM store_returns sr
    JOIN date_filter df ON sr.sr_returned_date_sk = df.d_date_sk
    GROUP BY sr_customer_sk
  ),
  web_agg AS (
    SELECT
      ws_bill_customer_sk AS cust_sk,
      SUM(ws_net_profit) AS web_net_profit,
      SUM(ws_net_paid) AS web_sales,
      COUNT(*) AS web_orders,
      MAX(ws_sold_date_sk) AS latest_web_date_sk
    FROM web_sales ws
    JOIN date_filter df ON ws.ws_sold_date_sk = df.d_date_sk
    GROUP BY ws_bill_customer_sk
  ),
  web_ret_agg AS (
    SELECT
      wr_returning_customer_sk AS cust_sk,
      SUM(wr_net_loss) AS web_net_loss,
      MAX(wr_returned_date_sk) AS latest_web_return_date_sk
    FROM web_returns wr
    JOIN date_filter df ON wr.wr_returned_date_sk = df.d_date_sk
    GROUP BY wr_returning_customer_sk
  ),
  combined AS (
    SELECT
      cb.cust_sk,
      cb.full_name,
      COALESCE(ca.catalog_net_profit,0) AS catalog_net_profit,
      COALESCE(cr.catalog_net_loss,0) AS catalog_net_loss,
      COALESCE(sa.store_net_profit,0) AS store_net_profit,
      COALESCE(sr.store_net_loss,0) AS store_net_loss,
      COALESCE(wa.web_net_profit,0) AS web_net_profit,
      COALESCE(wr.web_net_loss,0) AS web_net_loss,
      COALESCE(ca.latest_catalog_date_sk,0) AS latest_catalog_date_sk,
      COALESCE(cr.latest_catalog_return_date_sk,0) AS latest_catalog_return_date_sk,
      COALESCE(sa.latest_store_date_sk,0) AS latest_store_date_sk,
      COALESCE(sr.latest_store_return_date_sk,0) AS latest_store_return_date_sk,
      COALESCE(wa.latest_web_date_sk,0) AS latest_web_date_sk,
      COALESCE(wr.latest_web_return_date_sk,0) AS latest_web_return_date_sk
    FROM cust_base cb
    LEFT JOIN catalog_agg ca ON cb.cust_sk = ca.cust_sk
    LEFT JOIN catalog_ret_agg cr ON cb.cust_sk = cr.cust_sk
    LEFT JOIN store_agg sa ON cb.cust_sk = sa.cust_sk
    LEFT JOIN store_ret_agg sr ON cb.cust_sk = sr.cust_sk
    LEFT JOIN web_agg wa ON cb.cust_sk = wa.cust_sk
    LEFT JOIN web_ret_agg wr ON cb.cust_sk = wr.cust_sk
    WHERE (COALESCE(ca.catalog_net_profit,0) + COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0)) > 10000
      AND (
        (CASE WHEN COALESCE(ca.catalog_net_profit,0) > 0 THEN COALESCE(cr.catalog_net_loss,0) / COALESCE(ca.catalog_net_profit,1) ELSE 0 END) +
        (CASE WHEN COALESCE(sa.store_net_profit,0) > 0 THEN COALESCE(sr.store_net_loss,0) / COALESCE(sa.store_net_profit,1) ELSE 0 END) +
        (CASE WHEN COALESCE(wa.web_net_profit,0) > 0 THEN COALESCE(wr.web_net_loss,0) / COALESCE(wa.web_net_profit,1) ELSE 0 END)
      ) > 0.1
  ),
  ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (ORDER BY (catalog_net_profit + store_net_profit + web_net_profit) DESC) AS overall_rank,
      RANK() OVER (
        PARTITION BY 
          CASE 
            WHEN catalog_net_profit > 0 THEN 'Catalog' 
            WHEN store_net_profit > 0 THEN 'Store' 
            ELSE 'Web' 
          END
        ORDER BY (catalog_net_profit + store_net_profit + web_net_profit) DESC
      ) AS channel_rank
    FROM combined
  ),
  final_set AS (
    SELECT
      cust_sk,
      full_name,
      CONCAT('CUST_', LPAD(CAST(cust_sk AS VARCHAR), 6, '0')) AS cust_key,
      catalog_net_profit,
      store_net_profit,
      web_net_profit,
      (catalog_net_profit + store_net_profit + web_net_profit) AS total_net_profit,
      overall_rank,
      channel_rank,
      CASE 
        WHEN latest_catalog_date_sk > 0 THEN (SELECT d_date FROM date_dim WHERE d_date_sk = latest_catalog_date_sk)
        ELSE NULL 
      END AS latest_catalog_date,
      CASE 
        WHEN latest_store_date_sk > 0 THEN (SELECT d_date FROM date_dim WHERE d_date_sk = latest_store_date_sk)
        ELSE NULL 
      END AS latest_store_date,
      CASE 
        WHEN latest_web_date_sk > 0 THEN (SELECT d_date FROM date_dim WHERE d_date_sk = latest_web_date_sk)
        ELSE NULL 
      END AS latest_web_date,
      CASE 
        WHEN (catalog_net_loss + store_net_loss + web_net_loss) > (0.1 * (catalog_net_profit + store_net_profit + web_net_profit))
        THEN 'HIGH_RISK' 
        ELSE 'LOW_RISK' 
      END AS risk_flag
    FROM ranked
  ),
  top_customers AS (
    SELECT *
    FROM final_set
    WHERE overall_rank <= 100
  )
SELECT
  cust_sk,
  full_name,
  cust_key,
  catalog_net_profit,
  store_net_profit,
  web_net_profit,
  total_net_profit,
  overall_rank,
  channel_rank,
  latest_catalog_date,
  latest_store_date,
  latest_web_date,
  risk_flag
FROM top_customers

UNION ALL

SELECT
  CAST(NULL AS INTEGER) AS cust_sk,
  'ALL CHANNELS TOTAL' AS full_name,
  CAST(NULL AS VARCHAR) AS cust_key,
  (SELECT SUM(catalog_net_profit) FROM top_customers) AS catalog_net_profit,
  (SELECT SUM(store_net_profit) FROM top_customers) AS store_net_profit,
  (SELECT SUM(web_net_profit) FROM top_customers) AS web_net_profit,
  (SELECT SUM(total_net_profit) FROM top_customers) AS total_net_profit,
  CAST(NULL AS BIGINT) AS overall_rank,
  CAST(NULL AS BIGINT) AS channel_rank,
  CAST(NULL AS DATE) AS latest_catalog_date,
  CAST(NULL AS DATE) AS latest_store_date,
  CAST(NULL AS DATE) AS latest_web_date,
  CAST(NULL AS VARCHAR) AS risk_flag
ORDER BY overall_rank NULLS LAST, total_net_profit DESC
