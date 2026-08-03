WITH
web_agg AS (
   SELECT
       c.c_customer_id,
       d.d_year,
       SUM(ws.ws_ext_sales_price) + COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS metric,
       COUNT(DISTINCT ws.ws_order_number) AS cnt,
       'web_sales' AS src
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND t.t_hour BETWEEN 8 AND 18
     AND ca.ca_state = 'CA'
     AND ib.ib_upper_bound >= 50000
     AND i.i_brand = 'Brand#12'
     AND wp.wp_type = 'Content'
   GROUP BY c.c_customer_id, d.d_year
),
store_agg AS (
   SELECT
       c.c_customer_id,
       d.d_year,
       SUM(sr.sr_net_loss) AS metric,
       COUNT(DISTINCT sr.sr_ticket_number) AS cnt,
       'store_return' AS src
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN date_dim d2 ON s.s_closed_date_sk = d2.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND t.t_hour BETWEEN 8 AND 18
     AND s.s_state = 'CA'
     AND ib.ib_lower_bound <= 30000
     AND i.i_category = 'Electronics'
     AND ca.ca_location_type = 'condo'
   GROUP BY c.c_customer_id, d.d_year
),
web_ret_agg AS (
   SELECT
       c.c_customer_id,
       d.d_year,
       SUM(wr.wr_net_loss) AS metric,
       COUNT(DISTINCT wr.wr_order_number) AS cnt,
       'web_return' AS src
   FROM web_returns wr
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND t.t_hour BETWEEN 8 AND 18
     AND wp.wp_access_date_sk BETWEEN 2452572 AND 2452608
     AND ib.ib_upper_bound >= 40000
     AND i.i_brand_id IN (12, 13)
     AND ca.ca_city = 'Pine Oak'
   GROUP BY c.c_customer_id, d.d_year
),
combined AS (
   SELECT c_customer_id, d_year, metric, src, cnt FROM web_agg
   UNION DISTINCT
   SELECT c_customer_id, d_year, metric, src, cnt FROM store_agg
   UNION DISTINCT
   SELECT c_customer_id, d_year, metric, src, cnt FROM web_ret_agg
),
intersected AS (
   SELECT c_customer_id, d_year, metric, src, cnt
   FROM combined
   INTERSECT
   SELECT c_customer_id, d_year, metric, src, cnt
   FROM combined
   WHERE metric > 0
),
final AS (
   SELECT
       ic.c_customer_id,
       ic.d_year,
       SUM(ic.metric) AS total_metric,
       COUNT(DISTINCT ic.src) AS source_count,
       MAX(ic.cnt) AS max_cnt,
       la.avg_metric_per_source
   FROM intersected ic
   CROSS JOIN LATERAL (
        SELECT AVG(metric) AS avg_metric_per_source
        FROM intersected ic2
        WHERE ic2.c_customer_id = ic.c_customer_id
          AND ic2.d_year = ic.d_year
   ) AS la
   GROUP BY ic.c_customer_id, ic.d_year, la.avg_metric_per_source
   HAVING SUM(ic.metric) > 1000
)
SELECT
   c_customer_id,
   d_year,
   total_metric,
   source_count,
   max_cnt,
   avg_metric_per_source
FROM final
ORDER BY total_metric DESC
LIMIT 100
