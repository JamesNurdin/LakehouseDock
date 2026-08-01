WITH
  /* 1️⃣ Filtered web returns with realistic predicates */
  filtered_returns AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_refunded_addr_sk,
      wr.wr_returning_addr_sk,
      wr.wr_web_page_sk,
      wr.wr_reason_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_order_number
    FROM tpcds.web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450900 AND 2451100
      AND wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 10
      AND wr.wr_reason_sk IN (1, 7, 10)
  ),

  /* 2️⃣ Dimension scaffolds that bring in the date dimension once per source */
  store_dim AS (
    SELECT s.*, d.d_year AS store_year
    FROM tpcds.store s
    JOIN tpcds.date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
  ),
  call_center_dim AS (
    SELECT c.*, d.d_year AS cc_year
    FROM tpcds.call_center c
    JOIN tpcds.date_dim d ON c.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
  ),
  catalog_dim AS (
    SELECT cp.*, d.d_year AS catalog_year
    FROM tpcds.catalog_page cp
    JOIN tpcds.date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
  ),
  web_site_dim AS (
    SELECT ws.*, d.d_year AS website_year
    FROM tpcds.web_site ws
    JOIN tpcds.date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
  ),
  promotion_dim AS (
    SELECT p.*, ds.d_year AS promo_start_year, de.d_year AS promo_end_year
    FROM tpcds.promotion p
    JOIN tpcds.date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN tpcds.date_dim de ON p.p_end_date_sk = de.d_date_sk
    WHERE ds.d_year = 2002
  ),

  /* 3️⃣ First analytical branch – California focus */
  branch_ca AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      r.r_reason_desc,
      d_ret.d_year            AS return_year,
      SUM(fr.wr_return_quantity) AS total_qty,
      SUM(fr.wr_return_amt)      AS total_return_amt,
      AVG(fr.wr_return_amt)      AS avg_return_amt,
      CASE WHEN r.r_reason_desc LIKE '%damaged%' THEN 1 ELSE 0 END AS damaged_flag,
      COUNT(DISTINCT fr.wr_order_number) AS distinct_orders
    FROM filtered_returns fr
    JOIN tpcds.date_dim d_ret ON fr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN tpcds.item i ON fr.wr_item_sk = i.i_item_sk
    JOIN tpcds.reason r ON fr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.customer_address ca_refund ON fr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    LEFT JOIN tpcds.customer_address ca_return ON fr.wr_returning_addr_sk = ca_return.ca_address_sk
    LEFT JOIN tpcds.web_page wp ON fr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN store_dim s ON s.s_state = ca_return.ca_state
    LEFT JOIN call_center_dim cc ON cc.cc_state = ca_return.ca_state
    LEFT JOIN catalog_dim cp ON cp.cp_department = i.i_category
    LEFT JOIN web_site_dim ws ON ws.web_state = s.s_state
    LEFT JOIN promotion_dim p ON p.p_item_sk = i.i_item_sk
    RIGHT OUTER JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN tpcds.date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE i.i_class_id = 7
      AND i.i_manager_id IN (21, 34)
      AND ws.web_state = 'CA'
      AND cc.cc_state = 'CA'
      AND i.i_item_sk IN (
        SELECT i1.i_item_sk FROM tpcds.item i1 WHERE i1.i_category = 'Furniture'
        INTERSECT
        SELECT i2.i_item_sk FROM tpcds.item i2 WHERE i2.i_color = 'Red'
      )
    GROUP BY i.i_item_sk, i.i_product_name, r.r_reason_desc, d_ret.d_year
    HAVING SUM(fr.wr_return_amt) > 1000
  ),

  /* 4️⃣ Second analytical branch – New‑York focus, simpler joins */
  branch_ny AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      r.r_reason_desc,
      d_ret.d_year            AS return_year,
      SUM(fr.wr_return_quantity) AS total_qty,
      SUM(fr.wr_return_amt)      AS total_return_amt,
      AVG(fr.wr_return_amt)      AS avg_return_amt,
      CASE WHEN r.r_reason_desc LIKE '%damaged%' THEN 1 ELSE 0 END AS damaged_flag,
      COUNT(DISTINCT fr.wr_order_number) AS distinct_orders
    FROM filtered_returns fr
    JOIN tpcds.date_dim d_ret ON fr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN tpcds.item i ON fr.wr_item_sk = i.i_item_sk
    JOIN tpcds.reason r ON fr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN tpcds.date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    LEFT JOIN web_site_dim ws ON 1 = 1   -- cross‑join to expose the web‑site dimension
    WHERE i.i_class_id = 14
      AND ws.web_state = 'NY'
    GROUP BY i.i_item_sk, i.i_product_name, r.r_reason_desc, d_ret.d_year
    HAVING SUM(fr.wr_return_amt) > 500
  ),

  /* 5️⃣ Union of the two branches – distinct to force de‑duplication */
  unioned AS (
    SELECT * FROM branch_ca
    UNION
    SELECT * FROM branch_ny
  )

/* 6️⃣ Final projection with window function, ordering, and limit */
SELECT
  u.i_item_sk,
  u.i_product_name,
  u.return_year,
  u.total_qty,
  u.total_return_amt,
  u.avg_return_amt,
  u.damaged_flag,
  u.distinct_orders,
  ROW_NUMBER() OVER (ORDER BY u.total_return_amt DESC) AS rn
FROM unioned u
ORDER BY rn
LIMIT 100
