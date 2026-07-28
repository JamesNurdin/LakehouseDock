WITH sales_return_agg AS (
   SELECT
       ss.ss_sold_date_sk AS date_sk,
       d.d_year,
       p.p_promo_id,
       SUM(ss.ss_net_paid_inc_tax) AS total_sales,
       SUM(cr.cr_net_loss) AS total_return_loss,
       COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
       SUM(CASE WHEN ss.ss_net_paid_inc_tax > 5000 THEN 1 ELSE 0 END) AS high_value_sales_cnt
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2001
     AND cd.cd_purchase_estimate > 3000
     AND p.p_discount_active = 'Y'
     AND ss.ss_net_paid_inc_tax >= 100
   GROUP BY ss.ss_sold_date_sk, d.d_year, p.p_promo_id
)
SELECT
   a.d_year,
   a.p_promo_id,
   a.total_sales,
   a.total_return_loss,
   a.distinct_tickets,
   a.high_value_sales_cnt,
   CASE
       WHEN a.total_sales > 100000 THEN 'HIGH'
       WHEN a.total_sales BETWEEN 50000 AND 100000 THEN 'MEDIUM'
       ELSE 'LOW'
   END AS sales_category,
   a.avg_total_sales_over_year,
   ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank
FROM (
   SELECT
       agg.*, 
       (SELECT AVG(total_sales) FROM sales_return_agg WHERE d_year = agg.d_year) AS avg_total_sales_over_year
   FROM sales_return_agg agg
   WHERE agg.p_promo_id IN (
       SELECT DISTINCT p2.p_promo_id
       FROM promotion p2
       WHERE p2.p_channel_email = 'Y'
   )
) a
WHERE a.total_return_loss < a.total_sales * 0.2
ORDER BY a.d_year, a.total_sales DESC
LIMIT 100
