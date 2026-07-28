WITH sales_agg AS (
   SELECT
      ss.ss_store_sk,
      ss.ss_item_sk,
      ss.ss_sold_date_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_quantity) AS total_qty,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2001
     AND ca.ca_country = 'United States'
     AND i.i_brand = 'Brand#23'
     AND cd.cd_gender = 'M'
     AND hd.hd_vehicle_count >= 1
     AND s.s_state = 'CA'
   GROUP BY ss.ss_store_sk, ss.ss_item_sk, ss.ss_sold_date_sk
),
returns_agg AS (
   SELECT
      sr.sr_item_sk,
      sr.sr_store_sk,
      sr.sr_returned_date_sk,
      COUNT(*) AS return_cnt,
      SUM(sr.sr_refunded_cash) AS refunded_cash,
      MAX(r.r_reason_desc) AS top_reason
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   GROUP BY sr.sr_item_sk, sr.sr_store_sk, sr.sr_returned_date_sk
),
web_ret_agg AS (
   SELECT
      wr.wr_item_sk,
      wr.wr_returned_date_sk,
      COUNT(*) AS web_return_cnt,
      SUM(wr.wr_refunded_cash) AS web_refunded_cash,
      MAX(r.r_reason_desc) AS web_top_reason
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
)
SELECT DISTINCT
   s.s_store_name,
   i.i_item_id,
   d.d_date,
   sa.total_sales,
   sa.total_qty,
   sa.distinct_tickets,
   COALESCE(ra.return_cnt, 0) AS store_return_cnt,
   COALESCE(ra.refunded_cash, 0) AS store_refunded_cash,
   COALESCE(wa.web_return_cnt, 0) AS web_return_cnt,
   COALESCE(wa.web_refunded_cash, 0) AS web_refunded_cash,
   RANK() OVER (PARTITION BY s.s_store_sk ORDER BY sa.total_sales DESC) AS sales_rank_in_store
FROM sales_agg sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
LEFT JOIN returns_agg ra
   ON sa.ss_item_sk = ra.sr_item_sk
  AND sa.ss_store_sk = ra.sr_store_sk
  AND sa.ss_sold_date_sk = ra.sr_returned_date_sk
LEFT JOIN web_ret_agg wa
   ON sa.ss_item_sk = wa.wr_item_sk
  AND sa.ss_sold_date_sk = wa.wr_returned_date_sk
WHERE EXISTS (
      SELECT 1
      FROM web_sales ws
      JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
      WHERE ws.ws_item_sk = sa.ss_item_sk
        AND ws.ws_sold_date_sk = sa.ss_sold_date_sk
        AND w.web_country = 'United States'
        AND sm.sm_type = 'AIR'
   )
ORDER BY s.s_store_name, sa.total_sales DESC
LIMIT 100
