WITH sales_base AS (
   SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      d.d_year,
      i.i_brand,
      i.i_color,
      s.s_store_name,
      s.s_state,
      p.p_discount_active,
      inv.inv_quantity_on_hand,
      cc.cc_name,
      cp.cp_catalog_number,
      ws.web_name,
      wp.wp_url,
      r.r_reason_desc,
      wr.wr_return_amt,
      -- correlated scalar subquery per customer
      (SELECT AVG(ss2.ss_net_paid)
         FROM store_sales ss2
        WHERE ss2.ss_customer_sk = ss.ss_customer_sk) AS avg_customer_spent,
      -- compare quantity to a scalar max value
      CASE WHEN ss.ss_quantity > (SELECT MAX(ss3.ss_quantity) FROM store_sales ss3) / 2 THEN 1 ELSE 0 END AS high_quantity_flag,
      -- window function
      ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS rn
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
   LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
   LEFT JOIN catalog_page cp ON (cp.cp_start_date_sk = d.d_date_sk OR cp.cp_end_date_sk = d.d_date_sk)
   LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
   LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk AND wp.wp_customer_sk = c.c_customer_sk
   LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                         AND wr.wr_returned_time_sk = t.t_time_sk
                         AND wr.wr_item_sk = i.i_item_sk
   LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE d.d_year = 2001
     AND i.i_color = 'Red'
     AND s.s_state = 'CA'
     AND p.p_discount_active = 'Y'
     AND ss.ss_store_sk IN (SELECT s2.s_store_sk FROM store s2 WHERE s2.s_state = 'CA')
     AND NOT EXISTS (SELECT 1 FROM web_returns wr2 WHERE wr2.wr_order_number = ss.ss_ticket_number)
),
 lateral_inv AS (
   SELECT
      sb.*,
      inv_l.inv_quantity_on_hand AS lateral_qty
   FROM sales_base sb
   CROSS JOIN LATERAL (
      SELECT inv_quantity_on_hand
        FROM inventory inv_l
       WHERE inv_l.inv_item_sk = sb.ss_item_sk
         AND inv_l.inv_date_sk = sb.ss_sold_date_sk
       LIMIT 1
   ) AS inv_l
 ),
 agg AS (
   SELECT
      s_store_name,
      i_brand,
      d_year,
      SUM(ss_net_paid) AS total_net_paid,
      SUM(ss_quantity) AS total_quantity,
      AVG(ss_net_paid) AS avg_net_paid,
      COUNT(*) AS txn_cnt,
      GROUPING(s_store_name) AS g_store,
      GROUPING(i_brand) AS g_brand,
      GROUPING(d_year) AS g_year
   FROM lateral_inv
   GROUP BY ROLLUP (s_store_name, i_brand, d_year)
 )
SELECT
   s_store_name,
   i_brand,
   d_year,
   total_net_paid,
   total_quantity,
   avg_net_paid,
   txn_cnt,
   CASE
      WHEN g_store = 1 THEN 'All Stores'
      WHEN g_brand = 1 THEN 'All Brands'
      WHEN g_year  = 1 THEN 'All Years'
      ELSE 'Detail'
   END AS level_desc,
   (SELECT MAX(total_net_paid) FROM agg) AS max_total_net_paid_overall
FROM agg
WHERE total_net_paid > (SELECT AVG(total_net_paid) FROM agg)
ORDER BY total_net_paid DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
