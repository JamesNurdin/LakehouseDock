WITH full_join AS (
   SELECT
     ss.ss_sold_date_sk,
     ss.ss_sold_time_sk,
     ss.ss_store_sk,
     ss.ss_promo_sk,
     ss.ss_net_paid,
     ss.ss_quantity,
     s.s_store_id,
     s.s_state,
     p.p_promo_id,
     p.p_discount_active,
     d.d_date_sk,
     d.d_year,
     t.t_am_pm,
     ca.ca_address_sk,
     cd.cd_demo_sk,
     hd.hd_demo_sk,
     cr.cr_returned_date_sk,
     cr.cr_returned_time_sk,
     cr.cr_net_loss,
     cc.cc_call_center_sk,
     sm.sm_ship_mode_sk,
     w.w_warehouse_sk,
     wr.wr_returned_date_sk,
     wr.wr_returned_time_sk,
     wr.wr_net_loss AS web_net_loss
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                               AND cr.cr_returned_time_sk = t.t_time_sk
   LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                            AND wr.wr_returned_time_sk = t.t_time_sk
),
sales_agg AS (
   SELECT
     s_store_id,
     p_promo_id,
     d_year,
     ca_address_sk,
     SUM(ss_net_paid) AS total_sales,
     SUM(ss_quantity) AS total_qty
   FROM full_join
   WHERE d_year BETWEEN 2000 AND 2002
     AND s_state = 'CA'
     AND p_discount_active = 'Y'
     AND t_am_pm = 'PM'
   GROUP BY s_store_id, p_promo_id, d_year, ca_address_sk
),
returns_agg AS (
   SELECT
     s_store_id,
     p_promo_id,
     d_year,
     ca_address_sk,
     SUM(cr_net_loss) AS total_return_loss,
     COUNT(*) AS return_cnt
   FROM full_join
   WHERE cr_net_loss IS NOT NULL
     AND d_year BETWEEN 2000 AND 2002
     AND s_state = 'CA'
   GROUP BY s_store_id, p_promo_id, d_year, ca_address_sk
),
union_agg AS (
   SELECT
     s_store_id AS store_id,
     p_promo_id AS promo_id,
     d_year AS year,
     total_sales AS metric,
     ca_address_sk
   FROM sales_agg
   UNION DISTINCT
   SELECT
     s_store_id AS store_id,
     p_promo_id AS promo_id,
     d_year AS year,
     -total_return_loss AS metric,
     ca_address_sk
   FROM returns_agg
),
high_sales_store AS (
   SELECT store_id FROM union_agg WHERE metric > 50000
),
high_return_store AS (
   SELECT store_id FROM union_agg WHERE metric < -20000
),
intersect_stores AS (
   SELECT store_id FROM high_sales_store
   INTERSECT
   SELECT store_id FROM high_return_store
),
ranked AS (
   SELECT
     u.store_id,
     u.promo_id,
     u.year,
     u.metric,
     u.ca_address_sk,
     ROW_NUMBER() OVER (PARTITION BY u.store_id ORDER BY u.metric DESC) AS rnk,
     (SELECT COUNT(*)
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_addr_sk = u.ca_address_sk) AS addr_return_cnt
   FROM union_agg u
   WHERE u.store_id IN (SELECT store_id FROM intersect_stores)
)
SELECT
  store_id,
  promo_id,
  year,
  metric,
  rnk,
  addr_return_cnt
FROM ranked
WHERE rnk <= 3
ORDER BY store_id, metric DESC
LIMIT 100
