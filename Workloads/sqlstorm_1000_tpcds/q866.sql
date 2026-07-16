WITH
sales_raw AS (
  SELECT cs.cs_bill_customer_sk AS cust_sk,
         cs.cs_sold_date_sk AS date_sk,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         cs.cs_promo_sk AS promo_sk,
         cs.cs_call_center_sk AS call_center_sk,
         p.p_discount_active AS promo_active
  FROM catalog_sales cs
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  UNION ALL
  SELECT ss.ss_customer_sk,
         ss.ss_sold_date_sk,
         ss.ss_net_paid,
         ss.ss_net_profit,
         ss.ss_promo_sk,
         NULL,
         NULL
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_bill_customer_sk,
         ws.ws_sold_date_sk,
         ws.ws_net_paid,
         ws.ws_net_profit,
         ws.ws_promo_sk,
         NULL,
         NULL
  FROM web_sales ws
),
sales_agg AS (
  SELECT
    cust_sk,
    d.d_year AS year,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    COUNT(DISTINCT promo_sk) AS distinct_promo_cnt,
    SUM(CASE WHEN promo_active = 'Y' THEN 1 ELSE 0 END) AS active_promo_cnt,
    MAX(call_center_sk) AS call_center_sk
  FROM sales_raw s
  LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
  GROUP BY cust_sk, d.d_year
),
returns_raw AS (
  SELECT sr.sr_customer_sk AS cust_sk,
         sr.sr_returned_date_sk AS date_sk,
         sr.sr_net_loss AS net_loss
  FROM store_returns sr
  UNION ALL
  SELECT cr.cr_returning_customer_sk,
         cr.cr_returned_date_sk,
         cr.cr_net_loss
  FROM catalog_returns cr
  UNION ALL
  SELECT wr.wr_returning_customer_sk,
         wr.wr_returned_date_sk,
         wr.wr_net_loss
  FROM web_returns wr
),
returns_agg AS (
  SELECT
    cust_sk,
    d.d_year AS year,
    SUM(net_loss) AS total_net_loss,
    COUNT(*) AS returns_count
  FROM returns_raw r
  LEFT JOIN date_dim d ON r.date_sk = d.d_date_sk
  GROUP BY cust_sk, d.d_year
),
combined AS (
  SELECT
    COALESCE(sa.cust_sk, ra.cust_sk) AS cust_sk,
    COALESCE(sa.year, ra.year) AS year,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.sales_count,
    sa.distinct_promo_cnt,
    sa.active_promo_cnt,
    sa.call_center_sk,
    ra.total_net_loss,
    ra.returns_count
  FROM sales_agg sa
  FULL OUTER JOIN returns_agg ra
    ON sa.cust_sk = ra.cust_sk AND sa.year = ra.year
)
SELECT
  c.c_customer_id,
  concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
  combined.year,
  COALESCE(combined.total_net_paid, 0) AS total_net_paid,
  COALESCE(combined.total_net_profit, 0) AS total_net_profit,
  COALESCE(combined.total_net_loss, 0) AS total_net_loss,
  COALESCE(combined.sales_count, 0) AS sales_count,
  COALESCE(combined.returns_count, 0) AS returns_count,
  COALESCE(combined.distinct_promo_cnt, 0) AS distinct_promos,
  COALESCE(combined.active_promo_cnt, 0) AS active_promos,
  round((COALESCE(combined.total_net_profit,0) - COALESCE(combined.total_net_loss,0)) / nullif(COALESCE(combined.total_net_paid,0),0), 4) AS profit_loss_ratio,
  CASE WHEN (COALESCE(combined.total_net_profit,0) - COALESCE(combined.total_net_loss,0)) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_status,
  cc.cc_name AS call_center_name,
  ROW_NUMBER() OVER (PARTITION BY combined.year ORDER BY (COALESCE(combined.total_net_profit,0) - COALESCE(combined.total_net_loss,0)) DESC) AS rank_by_year,
  LAG(round((COALESCE(combined.total_net_profit,0) - COALESCE(combined.total_net_loss,0)) / nullif(COALESCE(combined.total_net_paid,0),0), 4), 1) OVER (PARTITION BY combined.cust_sk ORDER BY combined.year) AS prev_year_profit_loss_ratio,
  (SELECT COUNT(*) FROM customer_demographics cd WHERE cd.cd_demo_sk = c.c_current_cdemo_sk AND cd.cd_purchase_estimate > 5000) AS high_estimate_demo_count
FROM combined
LEFT JOIN customer c ON combined.cust_sk = c.c_customer_sk
LEFT JOIN call_center cc ON combined.call_center_sk = cc.cc_call_center_sk
WHERE combined.cust_sk IS NOT NULL
ORDER BY combined.year DESC, rank_by_year
LIMIT 100
