WITH
  base_returns AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_item_sk,
      cr.cr_refunded_customer_sk,
      cr.cr_refunded_hdemo_sk,
      cr.cr_refunded_addr_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_net_loss,
      i.i_current_price,
      d.d_year,
      c.c_first_name,
      c.c_last_name,
      ca.ca_location_type,
      hd.hd_vehicle_count,
      r.r_reason_desc,
      cp.cp_department,
      CASE
        WHEN cr.cr_return_amount > 100 THEN 'High'
        WHEN cr.cr_return_amount > 0   THEN 'Low'
        ELSE 'Zero'
      END AS return_category
    FROM catalog_returns cr
    JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i                   ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c               ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 50
      AND ca.ca_location_type = 'apartment'
      AND hd.hd_vehicle_count >= 2
      AND r.r_reason_desc LIKE '%missing%'
  ),
  store_cc AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_closed_date_sk,
      cc.cc_call_center_sk,
      cc.cc_name,
      d.d_year   AS store_year,
      d2.d_year  AS cc_year
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    FULL OUTER JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN date_dim d2 ON cc.cc_closed_date_sk = d2.d_date_sk
    WHERE d.d_year = 2001 OR d2.d_year = 2001
  ),
  inventory_items AS (
    SELECT inv.inv_item_sk
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  promotion_items AS (
    SELECT p.p_item_sk
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  item_diff AS (
    SELECT inv_item_sk FROM inventory_items
    EXCEPT
    SELECT p_item_sk FROM promotion_items
  )
SELECT
  br.d_year,
  br.return_category,
  COUNT(*)                                 AS return_cnt,
  SUM(br.cr_return_amount)                AS total_return_amount,
  AVG(br.i_current_price)                 AS avg_item_price,
  COUNT(DISTINCT br.cr_item_sk)           AS distinct_items,
  SUM(CASE WHEN sc.s_store_sk IS NOT NULL THEN 1 ELSE 0 END) AS store_match_cnt,
  COUNT(DISTINCT itdiff.inv_item_sk)      AS diff_item_cnt
FROM base_returns br
LEFT OUTER JOIN web_page wp       ON wp.wp_customer_sk = br.cr_refunded_customer_sk
LEFT OUTER JOIN time_dim td        ON br.cr_returned_time_sk = td.t_time_sk
JOIN store_cc sc                  ON (sc.s_store_sk IS NOT NULL OR sc.cc_call_center_sk IS NOT NULL)
LEFT JOIN inventory inv           ON inv.inv_item_sk = br.cr_item_sk
LEFT JOIN promotion p            ON p.p_item_sk = br.cr_item_sk
LEFT JOIN item_diff itdiff       ON itdiff.inv_item_sk = inv.inv_item_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM promotion p2
        JOIN date_dim d2 ON p2.p_start_date_sk = d2.d_date_sk
        WHERE p2.p_item_sk = br.cr_item_sk
          AND d2.d_year = 2001
      )
GROUP BY br.d_year, br.return_category
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
