WITH
  cr_dd AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_catalog_page_sk,
      cr.cr_warehouse_sk,
      cr.cr_reason_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_net_loss,
      dd.d_date,
      dd.d_year,
      dd.d_month_seq,
      dd.d_day_name
    FROM catalog_returns cr
    FULL OUTER JOIN date_dim dd
      ON cr.cr_returned_date_sk = dd.d_date_sk
  ),
  wp_ws AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_url,
      wp.wp_type,
      wp.wp_creation_date_sk,
      ws.web_site_sk,
      ws.web_name,
      ws.web_state,
      ws.web_open_date_sk,
      ws.web_close_date_sk,
      d_open.d_date    AS open_date,
      d_close.d_date   AS close_date
    FROM web_page wp
    JOIN date_dim d_open
      ON wp.wp_creation_date_sk = d_open.d_date_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
      ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE ws.web_state IN ('CA', 'TX', 'NY')
      AND wp.wp_type = 'Home'
  ),
  page_keys_1 AS (
    SELECT cp_catalog_page_sk
    FROM catalog_page
    WHERE cp_type = 'Catalog' AND cp_department = 'Sports'
  ),
  page_keys_2 AS (
    SELECT cp.cp_catalog_page_sk
    FROM catalog_page cp
    JOIN date_dim d
      ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_month_seq = 2
  ),
  common_page_keys AS (
    SELECT cp_catalog_page_sk FROM page_keys_1
    INTERSECT
    SELECT cp_catalog_page_sk FROM page_keys_2
  ),
  final AS (
    SELECT
      dd.d_year,
      dd.d_month_seq,
      r.r_reason_desc,
      w.w_state,
      COUNT(cr.cr_return_quantity)                                   AS total_returns,
      SUM(cr.cr_return_amount)                                        AS total_return_amount,
      AVG(cr.cr_return_amount)                                        AS avg_return_amount,
      MIN(cr.cr_return_amount)                                        AS min_return_amount,
      MAX(cr.cr_return_amount)                                        AS max_return_amount,
      (SELECT COUNT(*) FROM catalog_returns WHERE cr_return_amount > 1000) AS high_value_return_cnt
    FROM cr_dd cr
    JOIN date_dim dd
      ON cr.cr_returned_date_sk = dd.d_date_sk
    LEFT JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN time_dim td
      ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN common_page_keys cpk
      ON cp.cp_catalog_page_sk = cpk.cp_catalog_page_sk
    WHERE dd.d_year BETWEEN 2000 AND 2002
      AND td.t_shift = 'first'
      AND w.w_warehouse_sq_ft > 500000
      AND r.r_reason_desc LIKE '%size%'
      AND cp.cp_department = 'Clothing'
      AND cp.cp_catalog_number IN (101, 202, 303)
    GROUP BY dd.d_year, dd.d_month_seq, r.r_reason_desc, w.w_state
  )
SELECT *
FROM final
ORDER BY total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
