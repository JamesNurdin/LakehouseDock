WITH
  base1 AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      d.d_year,
      i.i_brand,
      i.i_category,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ws.web_name,
      inv.inv_quantity_on_hand,
      w.w_warehouse_name
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  ),
  base2 AS (
    SELECT
      wr.wr_order_number AS order_num,
      wr.wr_return_amt * 1.1 AS adj_return_amt,
      d2.d_month_seq,
      i2.i_brand AS brand2,
      cd2.cd_gender AS gender2,
      hd2.hd_income_band_sk AS hd_income2,
      inv2.inv_quantity_on_hand AS inv_qty2
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    JOIN customer_demographics cd2 ON wr.wr_returning_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON wr.wr_returning_hdemo_sk = hd2.hd_demo_sk
    JOIN inventory inv2 ON inv2.inv_date_sk = d2.d_date_sk AND inv2.inv_item_sk = i2.i_item_sk
  ),
  full_joined AS (
    SELECT *
    FROM base1
    FULL OUTER JOIN base2 ON base1.wr_order_number = base2.order_num
  ),
  unified AS (
    SELECT
      fj.wr_order_number AS order_number,
      fj.wr_return_amt,
      fj.adj_return_amt,
      fj.i_brand,
      fj.brand2,
      fj.d_year,
      fj.d_month_seq
    FROM full_joined fj
    UNION
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      NULL AS adj_return_amt,
      i.i_brand,
      NULL AS brand2,
      d.d_year,
      d.d_month_seq
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_site ws ON ws.web_close_date_sk = d.d_date_sk
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_order_number NOT IN (
        SELECT wr2.wr_order_number
        FROM web_returns wr2
        JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
        WHERE r2.r_reason_desc = 'Damaged'
      )
  )
SELECT
  u.order_number,
  SUM(COALESCE(u.wr_return_amt, 0)) AS total_return,
  SUM(COALESCE(u.adj_return_amt, 0)) AS total_adj_return,
  COUNT(DISTINCT COALESCE(u.i_brand, u.brand2)) AS distinct_brands,
  MIN(COALESCE(u.d_year, u.d_month_seq)) AS first_period,
  MAX(COALESCE(u.d_year, u.d_month_seq)) AS last_period
FROM unified u
GROUP BY u.order_number
HAVING SUM(COALESCE(u.wr_return_amt, 0)) > 0
EXCEPT
SELECT
  wr.wr_order_number,
  SUM(wr.wr_return_amt) AS total_return,
  0.0 AS total_adj_return,
  COUNT(DISTINCT i.i_brand) AS distinct_brands,
  MIN(d.d_year) AS first_period,
  MAX(d.d_year) AS last_period
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
GROUP BY wr.wr_order_number
ORDER BY total_return DESC
LIMIT 100
