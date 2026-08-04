WITH
  agg_sales AS (
    SELECT
      d_sales.d_date AS d_date,
      i.i_item_id AS i_item_id,
      sm.sm_ship_mode_id AS sm_ship_mode_id,
      w.w_warehouse_id AS w_warehouse_id,
      r.r_reason_desc AS r_reason_desc,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(cr.cr_return_amount) AS total_returns,
      CASE WHEN SUM(cr.cr_return_amount) > 0 THEN 'RETURNED' ELSE 'NO_RETURN' END AS return_flag,
      ROW_NUMBER() OVER (PARTITION BY d_sales.d_date ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN date_dim d_sales
      ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
      ON cr.cr_item_sk = i.i_item_sk
     AND cr.cr_returned_date_sk = d_sales.d_date_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
     AND inv.inv_date_sk = d_sales.d_date_sk
    JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
     AND wp.wp_creation_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2001
      AND i.i_current_price > 20
      AND w.w_state = 'CA'
      AND r.r_reason_desc LIKE '%color%'
      AND ss.ss_ext_sales_price > 1000
    GROUP BY CUBE (d_sales.d_date, i.i_item_id, sm.sm_ship_mode_id, w.w_warehouse_id, r.r_reason_desc)
  ),
  high_returns AS (
    SELECT
      d_sales.d_date AS d_date,
      i.i_item_id AS i_item_id
    FROM store_sales ss
    JOIN date_dim d_sales
      ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN catalog_returns cr
      ON cr.cr_item_sk = i.i_item_sk
     AND cr.cr_returned_date_sk = d_sales.d_date_sk
    WHERE cr.cr_return_amount > 2000
    GROUP BY d_sales.d_date, i.i_item_id
    HAVING SUM(cr.cr_return_amount) > 5000
  )
SELECT
  a.d_date,
  a.i_item_id,
  a.sm_ship_mode_id,
  a.w_warehouse_id,
  a.r_reason_desc,
  a.total_sales,
  a.total_returns,
  a.return_flag,
  a.sales_rank,
  (SELECT AVG(b.total_sales) FROM agg_sales b) AS avg_total_sales_overall
FROM agg_sales a
WHERE (a.d_date, a.i_item_id) IN (
        SELECT d_date, i_item_id FROM high_returns
        INTERSECT
        SELECT d_date, i_item_id FROM agg_sales WHERE total_sales > 8000
      )
ORDER BY a.total_sales DESC, a.sales_rank
LIMIT 100
