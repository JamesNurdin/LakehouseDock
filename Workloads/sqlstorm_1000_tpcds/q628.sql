WITH store_sales_ext AS (
   SELECT
       ss.ss_sold_date_sk AS date_sk,
       ss.ss_store_sk AS store_sk,
       CAST(NULL AS integer) AS catalog_page_sk,
       CAST(NULL AS integer) AS web_page_sk,
       ss.ss_customer_sk AS customer_sk,
       ss.ss_quantity AS quantity,
       ss.ss_net_paid AS net_paid,
       ss.ss_net_profit AS net_profit,
       'store' AS channel,
       CAST(NULL AS varchar) AS ship_mode_type,
       CAST(NULL AS varchar) AS call_center_name,
       p.p_promo_name AS promo_name
   FROM store_sales ss
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
),
web_sales_ext AS (
   SELECT
       ws.ws_sold_date_sk AS date_sk,
       CAST(NULL AS integer) AS store_sk,
       CAST(NULL AS integer) AS catalog_page_sk,
       ws.ws_web_page_sk AS web_page_sk,
       ws.ws_bill_customer_sk AS customer_sk,
       ws.ws_quantity AS quantity,
       ws.ws_net_paid AS net_paid,
       ws.ws_net_profit AS net_profit,
       'web' AS channel,
       sm.sm_type AS ship_mode_type,
       CAST(NULL AS varchar) AS call_center_name,
       p.p_promo_name AS promo_name
   FROM web_sales ws
   LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
catalog_sales_ext AS (
   SELECT
       cs.cs_sold_date_sk AS date_sk,
       CAST(NULL AS integer) AS store_sk,
       cs.cs_catalog_page_sk AS catalog_page_sk,
       CAST(NULL AS integer) AS web_page_sk,
       cs.cs_bill_customer_sk AS customer_sk,
       cs.cs_quantity AS quantity,
       cs.cs_net_paid AS net_paid,
       cs.cs_net_profit AS net_profit,
       'catalog' AS channel,
       sm.sm_type AS ship_mode_type,
       cc.cc_name AS call_center_name,
       p.p_promo_name AS promo_name
   FROM catalog_sales cs
   LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
),
sales_union AS (
   SELECT * FROM store_sales_ext
   UNION ALL
   SELECT * FROM web_sales_ext
   UNION ALL
   SELECT * FROM catalog_sales_ext
),
date_sales AS (
   SELECT
       d.d_date,
       d.d_year,
       d.d_month_seq,
       s.channel,
       sum(s.net_paid) AS total_net_paid,
       sum(s.net_profit) AS total_net_profit,
       sum(s.quantity) AS total_quantity,
       count(*) AS txn_count,
       count(DISTINCT s.customer_sk) AS distinct_customer_cnt,
       approx_percentile(s.net_profit, 0.5) AS median_profit,
       max(s.promo_name) FILTER (WHERE s.promo_name IS NOT NULL) AS sample_promo_name
   FROM sales_union s
   JOIN date_dim d ON s.date_sk = d.d_date_sk
   WHERE d.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
   GROUP BY d.d_date, d.d_year, d.d_month_seq, s.channel
),
ranked_sales AS (
   SELECT
       ds.*,
       rank() OVER (PARTITION BY ds.channel ORDER BY ds.total_net_profit DESC) AS profit_rank,
       percent_rank() OVER (PARTITION BY ds.channel ORDER BY ds.total_net_profit) AS profit_percent_rank,
       avg(ds.total_net_profit) OVER (PARTITION BY ds.channel ORDER BY ds.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d_profit
   FROM date_sales ds
),
returns_union AS (
   SELECT
       cr.cr_returned_date_sk AS date_sk,
       'catalog' AS channel,
       cr.cr_return_quantity AS quantity,
       cr.cr_return_amount AS return_amount,
       cr.cr_net_loss AS net_loss
   FROM catalog_returns cr
   UNION ALL
   SELECT
       sr.sr_returned_date_sk,
       'store' AS channel,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       sr.sr_net_loss
   FROM store_returns sr
   UNION ALL
   SELECT
       wr.wr_returned_date_sk,
       'web' AS channel,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       wr.wr_net_loss
   FROM web_returns wr
),
date_returns AS (
   SELECT
       d.d_date,
       r.channel,
       sum(r.quantity) AS total_return_qty,
       sum(r.return_amount) AS total_return_amount,
       sum(r.net_loss) AS total_return_loss
   FROM returns_union r
   JOIN date_dim d ON r.date_sk = d.d_date_sk
   GROUP BY d.d_date, r.channel
),
final AS (
   SELECT
       rs.d_date,
       rs.d_year,
       rs.channel,
       rs.total_net_paid,
       rs.total_net_profit,
       rs.total_quantity,
       rs.txn_count,
       rs.distinct_customer_cnt,
       rs.median_profit,
       rs.sample_promo_name,
       rs.profit_rank,
       rs.profit_percent_rank,
       rs.moving_avg_7d_profit,
       COALESCE(dr.total_return_qty, 0) AS total_return_qty,
       COALESCE(dr.total_return_amount, 0) AS total_return_amount,
       COALESCE(dr.total_return_loss, 0) AS total_return_loss,
       CASE
           WHEN rs.total_net_profit > 0 AND COALESCE(dr.total_return_loss, 0) > rs.total_net_profit * 0.1 THEN 'ALERT_HIGH_LOSS'
           WHEN rs.total_net_profit < 0 THEN 'NEGATIVE_PROFIT'
           ELSE 'NORMAL'
       END AS profit_status
   FROM ranked_sales rs
   LEFT JOIN date_returns dr ON rs.d_date = dr.d_date AND rs.channel = dr.channel
   WHERE rs.total_net_paid IS NOT NULL
)
SELECT
    f.d_date,
    f.channel,
    f.total_net_paid,
    f.total_net_profit,
    f.total_quantity,
    f.txn_count,
    f.distinct_customer_cnt,
    f.median_profit,
    coalesce(f.sample_promo_name, 'N/A') AS promo_name,
    f.profit_rank,
    f.profit_percent_rank,
    round(f.moving_avg_7d_profit, 2) AS moving_avg_7d_profit,
    f.total_return_qty,
    f.total_return_amount,
    f.total_return_loss,
    f.profit_status,
    concat(f.channel, ':', f.profit_status) AS channel_status_desc,
    nullif(f.total_net_paid, 0) AS net_paid_non_zero,
    COALESCE(
        (SELECT max(d2.d_date) FROM date_dim d2 WHERE d2.d_date <= f.d_date AND d2.d_year = f.d_year),
        DATE '1900-01-01'
    ) AS latest_date_of_year
FROM final f
ORDER BY f.d_date DESC, f.channel
