WITH store_sales_agg AS (
    SELECT ss_store_sk AS store_sk,
           ss_sold_date_sk AS date_sk,
           SUM(ss_net_paid) AS store_net_paid,
           SUM(ss_net_profit) AS store_net_profit
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk
),
catalog_sales_agg AS (
    SELECT cs_call_center_sk AS store_sk,
           cs_sold_date_sk AS date_sk,
           SUM(cs_net_paid_inc_tax) AS store_net_paid,
           SUM(cs_net_profit) AS store_net_profit
    FROM catalog_sales
    GROUP BY cs_call_center_sk, cs_sold_date_sk
),
web_sales_agg AS (
    SELECT ws_warehouse_sk AS store_sk,
           ws_sold_date_sk AS date_sk,
           SUM(ws_net_paid) AS store_net_paid,
           SUM(ws_net_profit) AS store_net_profit
    FROM web_sales
    GROUP BY ws_warehouse_sk, ws_sold_date_sk
),
combined_sales AS (
    SELECT store_sk,
           date_sk,
           store_net_paid,
           store_net_profit,
           CAST('STORE' AS VARCHAR) AS channel
    FROM store_sales_agg
    UNION ALL
    SELECT store_sk,
           date_sk,
           store_net_paid,
           store_net_profit,
           CAST('CATALOG' AS VARCHAR) AS channel
    FROM catalog_sales_agg
    UNION ALL
    SELECT store_sk,
           date_sk,
           store_net_paid,
           store_net_profit,
           CAST('WEB' AS VARCHAR) AS channel
    FROM web_sales_agg
),
sales_monthly AS (
    SELECT c.store_sk,
           d.d_year,
           d.d_month_seq AS month_seq,
           c.channel,
           SUM(c.store_net_paid) AS total_net_paid,
           SUM(c.store_net_profit) AS total_net_profit
    FROM combined_sales c
    JOIN date_dim d ON c.date_sk = d.d_date_sk
    GROUP BY c.store_sk, d.d_year, d.d_month_seq, c.channel
),
store_returns_monthly AS (
    SELECT sr.sr_store_sk AS store_sk,
           d.d_year,
           d.d_month_seq AS month_seq,
           SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
),
sales_by_month AS (
    SELECT sm.d_year,
           sm.month_seq,
           sm.store_sk,
           sm.channel,
           sm.total_net_paid,
           sm.total_net_profit,
           COALESCE(srm.total_net_loss, 0) AS total_net_loss
    FROM sales_monthly sm
    LEFT JOIN store_returns_monthly srm
        ON sm.store_sk = srm.store_sk
       AND sm.month_seq = srm.month_seq
       AND sm.d_year = srm.d_year
),
rolling_profit AS (
    SELECT *,
           AVG(total_net_profit) OVER (PARTITION BY store_sk, channel ORDER BY month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_3mo_avg
    FROM sales_by_month
),
ranked_profit AS (
    SELECT r.*,
           ROW_NUMBER() OVER (PARTITION BY r.month_seq, r.channel ORDER BY r.total_net_profit DESC) AS profit_rank
    FROM rolling_profit r
),
top_customers AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY store_sk, month_seq ORDER BY cust_net_paid DESC) AS rn
    FROM (
        SELECT ss.ss_store_sk AS store_sk,
               d.d_month_seq AS month_seq,
               ss.ss_customer_sk AS customer_sk,
               SUM(ss.ss_net_paid) AS cust_net_paid
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY ss.ss_store_sk, d.d_month_seq, ss.ss_customer_sk
    ) t
),
top_customers_filtered AS (
    SELECT store_sk, month_seq, customer_sk, cust_net_paid
    FROM top_customers
    WHERE rn = 1
),
final_result AS (
    SELECT rp.d_year,
           rp.month_seq,
           COALESCE(st.s_store_name, cc.cc_name, w.w_warehouse_name) AS location_name,
           rp.store_sk,
           rp.channel,
           rp.total_net_paid,
           rp.total_net_profit,
           rp.total_net_loss,
           rp.profit_3mo_avg,
           CASE WHEN rp.profit_3mo_avg > 0 THEN rp.total_net_profit / rp.profit_3mo_avg ELSE NULL END AS profit_vs_rolling,
           tc.cust_net_paid AS top_customer_spend,
           CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS top_customer_name,
           CASE 
               WHEN rp.total_net_profit > 0 THEN 'POSITIVE'
               WHEN rp.total_net_profit < 0 THEN 'NEGATIVE'
               ELSE 'ZERO'
           END AS profit_category,
           rp.profit_rank,
           (SELECT MAX(sbm.total_net_profit) FROM sales_by_month sbm WHERE sbm.month_seq = rp.month_seq) AS month_max_total_net_profit,
           CONCAT('Store_', CAST(rp.store_sk AS VARCHAR), '_', rp.channel) AS unique_id
    FROM ranked_profit rp
    LEFT JOIN store st ON rp.store_sk = st.s_store_sk
    LEFT JOIN call_center cc ON rp.store_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w ON rp.store_sk = w.w_warehouse_sk
    LEFT JOIN top_customers_filtered tc ON rp.store_sk = tc.store_sk AND rp.month_seq = tc.month_seq
    LEFT JOIN customer c ON tc.customer_sk = c.c_customer_sk
    WHERE CASE 
              WHEN rp.total_net_profit > 0 THEN 'POSITIVE'
              WHEN rp.total_net_profit < 0 THEN 'NEGATIVE'
              ELSE 'ZERO'
          END = 'POSITIVE'
)
SELECT *
FROM final_result
ORDER BY d_year DESC, month_seq DESC, total_net_profit DESC
