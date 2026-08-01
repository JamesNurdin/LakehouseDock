WITH cs_base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sales_price,
       d.d_year,
       cp.cp_department,
       p.p_promo_name
   FROM catalog_sales cs
   JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
),
cs_filtered AS (
   SELECT *
   FROM cs_base cfb
   WHERE NOT EXISTS (
         SELECT 1
         FROM store_sales ss
         WHERE ss.ss_ticket_number = cfb.cs_order_number
   )
),
ss_base AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_sales_price,
       d2.d_year,
       p2.p_promo_name
   FROM store_sales ss
   RIGHT OUTER JOIN store s          ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d2                  ON ss.ss_sold_date_sk = d2.d_date_sk
   LEFT JOIN promotion p2            ON ss.ss_promo_sk = p2.p_promo_sk
   LEFT JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
   LEFT JOIN customer c2               ON ss.ss_customer_sk = c2.c_customer_sk
),
web_ret_base AS (
   SELECT
       wr.wr_return_quantity,
       d3.d_year,
       r.r_reason_desc,
       wp.wp_type,
       ws.web_name
   FROM web_returns wr
   JOIN date_dim d3               ON wr.wr_returned_date_sk = d3.d_date_sk
   JOIN reason r                  ON wr.wr_reason_sk = r.r_reason_sk
   JOIN web_page wp               ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN web_site ws               ON ws.web_open_date_sk = d3.d_date_sk
),
order_excl AS (
   SELECT cs_order_number FROM cs_base
   EXCEPT
   SELECT ss_ticket_number FROM ss_base
),
cs_agg AS (
   SELECT
       d_year AS year,
       cp_department AS department,
       SUM(cs_sales_price) AS total_sales,
       COUNT(DISTINCT p_promo_name) AS promo_count
   FROM cs_filtered
   GROUP BY d_year, cp_department
),
ss_agg AS (
   SELECT
       d_year AS year,
       'Store' AS department,
       SUM(ss_sales_price) AS total_returns,
       COUNT(DISTINCT p_promo_name) AS promo_count
   FROM ss_base
   GROUP BY d_year
),
wr_agg AS (
   SELECT
       d_year AS year,
       SUM(wr_return_quantity) AS return_qty
   FROM web_ret_base
   GROUP BY d_year
),
union_agg AS (
   SELECT year, department, total_sales, promo_count FROM cs_agg
   UNION
   SELECT year, department, total_returns AS total_sales, promo_count FROM ss_agg
)
SELECT
   u.year,
   u.department,
   COALESCE(u.total_sales, 0) AS total_sales,
   COALESCE(w.return_qty, 0) AS total_return_qty,
   CASE WHEN COALESCE(w.return_qty, 0) = 0 THEN 0
        ELSE COALESCE(u.total_sales, 0) / COALESCE(w.return_qty, 0) END AS sales_return_ratio,
   u.promo_count
FROM union_agg u
FULL OUTER JOIN wr_agg w
     ON u.year = w.year
ORDER BY u.year DESC, u.department
OFFSET 20 ROWS
LIMIT 100
