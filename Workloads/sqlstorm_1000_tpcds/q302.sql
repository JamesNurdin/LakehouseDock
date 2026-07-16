WITH
  date_range AS (
    SELECT max(d_date) AS max_date
    FROM date_dim
  ),
  filtered_dates AS (
    SELECT d.d_date_sk
    FROM date_dim d
    CROSS JOIN date_range dr
    WHERE d.d_date BETWEEN date_add('day', -365, dr.max_date) AND dr.max_date
  ),
  sales_union AS (
    SELECT
      ss.ss_customer_sk AS c_customer_sk,
      ss.ss_sold_date_sk AS d_date_sk,
      ss.ss_net_profit AS net_profit,
      ss.ss_quantity AS quantity,
      ss.ss_net_paid AS net_paid,
      'store' AS channel,
      ss.ss_store_sk AS store_sk,
      CAST(NULL AS integer) AS call_center_sk
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM filtered_dates)
    UNION ALL
    SELECT
      cs.cs_bill_customer_sk AS c_customer_sk,
      cs.cs_sold_date_sk AS d_date_sk,
      cs.cs_net_profit AS net_profit,
      cs.cs_quantity AS quantity,
      cs.cs_net_paid AS net_paid,
      'catalog' AS channel,
      CAST(NULL AS integer) AS store_sk,
      cs.cs_call_center_sk AS call_center_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM filtered_dates)
    UNION ALL
    SELECT
      ws.ws_bill_customer_sk AS c_customer_sk,
      ws.ws_sold_date_sk AS d_date_sk,
      ws.ws_net_profit AS net_profit,
      ws.ws_quantity AS quantity,
      ws.ws_net_paid AS net_paid,
      'web' AS channel,
      CAST(NULL AS integer) AS store_sk,
      CAST(NULL AS integer) AS call_center_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM filtered_dates)
  ),
  agg_sales AS (
    SELECT
      c_customer_sk,
      channel,
      call_center_sk,
      SUM(net_profit) AS total_profit,
      SUM(quantity) AS total_quantity,
      SUM(net_paid) AS total_paid,
      COUNT(DISTINCT d_date_sk) AS active_days,
      MAX(d_date_sk) AS last_sale_date_sk
    FROM sales_union
    GROUP BY c_customer_sk, channel, call_center_sk
  ),
  ranked_customers AS (
    SELECT
      a.*,
      ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS profit_rank,
      AVG(total_profit) OVER (PARTITION BY channel) AS avg_profit_channel
    FROM agg_sales a
  ),
  multi_channel_customers AS (
    SELECT
      c_customer_sk
    FROM agg_sales
    GROUP BY c_customer_sk
    HAVING COUNT(DISTINCT channel) >= 2
  ),
  customers_with_returns AS (
    SELECT DISTINCT sr_customer_sk AS c_customer_sk
    FROM store_returns
    UNION
    SELECT DISTINCT cr_returning_customer_sk
    FROM catalog_returns
    UNION
    SELECT DISTINCT wr_returning_customer_sk
    FROM web_returns
  ),
  final_customers AS (
    SELECT
      rc.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      COALESCE(c.c_preferred_cust_flag, 'N') AS preferred_flag,
      rc.channel,
      rc.total_profit,
      rc.total_quantity,
      rc.total_paid,
      rc.profit_rank,
      rc.avg_profit_channel,
      d.d_date AS last_sale_date,
      cc.cc_name AS call_center_name,
      CASE WHEN cr.c_customer_sk IS NOT NULL THEN 'Yes' ELSE 'No' END AS has_return
    FROM ranked_customers rc
    JOIN customer c ON rc.c_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON rc.last_sale_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON rc.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN customers_with_returns cr ON rc.c_customer_sk = cr.c_customer_sk
    WHERE rc.c_customer_sk IN (SELECT c_customer_sk FROM multi_channel_customers)
      AND rc.profit_rank <= 10
  )
SELECT
  CONCAT_WS(' ', f.c_first_name, f.c_last_name) AS full_name,
  f.preferred_flag,
  f.channel,
  f.total_profit,
  f.total_quantity,
  f.total_paid,
  f.profit_rank,
  f.avg_profit_channel,
  CAST(f.last_sale_date AS varchar) AS last_sale_date,
  COALESCE(f.call_center_name, 'N/A') AS call_center_name,
  f.has_return,
  CASE
    WHEN f.total_profit > f.avg_profit_channel * 2 THEN 'High'
    WHEN f.total_profit > f.avg_profit_channel THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS profit_category,
  CASE
    WHEN f.call_center_name IS NULL AND f.channel = 'catalog' THEN 'Missing Call Center'
    ELSE NULL
  END AS anomaly_flag,
  (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_customer_sk = f.c_customer_sk) AS store_return_count
FROM final_customers f
ORDER BY f.channel, f.profit_rank
