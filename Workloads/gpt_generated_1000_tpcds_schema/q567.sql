WITH
  inventory_agg AS (
    SELECT inv.inv_warehouse_sk,
           SUM(inv.inv_quantity_on_hand) AS wh_total_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY inv.inv_warehouse_sk
  ),

  catalog_agg AS (
    SELECT
      cr.cr_refunded_customer_sk AS customer_sk,
      SUM(cr.cr_return_amount) AS cat_return_amt,
      SUM(cr.cr_net_loss) AS cat_net_loss,
      COUNT(*) AS cat_return_cnt,
      MAX(cr.cr_warehouse_sk) AS warehouse_sk,
      MAX(r.r_reason_desc) AS cat_reason_desc,
      MAX(cd.cd_gender) AS cat_gender
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%Did not like%'
    GROUP BY cr.cr_refunded_customer_sk
  ),

  store_agg AS (
    SELECT
      sr.sr_customer_sk AS customer_sk,
      SUM(sr.sr_return_amt) AS store_return_amt,
      SUM(sr.sr_net_loss) AS store_net_loss,
      COUNT(*) AS store_return_cnt,
      MAX(s.s_store_name) AS store_name,
      MAX(r.r_reason_desc) AS store_reason_desc,
      MAX(cd.cd_gender) AS store_gender
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%No service%'
    GROUP BY sr.sr_customer_sk
  ),

  web_agg AS (
    SELECT
      wr.wr_refunded_customer_sk AS customer_sk,
      SUM(wr.wr_return_amt) AS web_return_amt,
      SUM(wr.wr_net_loss) AS web_net_loss,
      COUNT(*) AS web_return_cnt,
      MAX(wp.wp_url) AS web_page_url,
      MAX(r.r_reason_desc) AS web_reason_desc,
      MAX(cd.cd_gender) AS web_gender
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%Gift%'
    GROUP BY wr.wr_refunded_customer_sk
  ),

  customer_returns AS (
    SELECT
      c.c_customer_sk,
      c.c_birth_month,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      COALESCE(cat.cat_return_amt, 0) + COALESCE(st.store_return_amt, 0) + COALESCE(web.web_return_amt, 0) AS total_return_amt,
      COALESCE(cat.cat_net_loss, 0) + COALESCE(st.store_net_loss, 0) + COALESCE(web.web_net_loss, 0) AS total_net_loss,
      COALESCE(cat.cat_return_cnt, 0) + COALESCE(st.store_return_cnt, 0) + COALESCE(web.web_return_cnt, 0) AS total_return_cnt,
      CASE
        WHEN COALESCE(cat.cat_return_cnt, 0) + COALESCE(st.store_return_cnt, 0) + COALESCE(web.web_return_cnt, 0) > 10 THEN 'Heavy'
        WHEN COALESCE(cat.cat_return_cnt, 0) + COALESCE(st.store_return_cnt, 0) + COALESCE(web.web_return_cnt, 0) BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Light'
      END AS return_intensity,
      COALESCE(cat.warehouse_sk, 0) AS warehouse_sk,
      COALESCE(inv.wh_total_on_hand, 0) AS warehouse_inventory_on_hand
    FROM customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_agg cat ON c.c_customer_sk = cat.customer_sk
    LEFT JOIN store_agg st ON c.c_customer_sk = st.customer_sk
    LEFT JOIN web_agg web ON c.c_customer_sk = web.customer_sk
    LEFT JOIN inventory_agg inv ON cat.warehouse_sk = inv.inv_warehouse_sk
    WHERE c.c_birth_month IN (3, 5, 7, 9, 10)
  ),

  catalog_only_customers AS (
    SELECT DISTINCT customer_sk FROM catalog_agg
    EXCEPT
    SELECT DISTINCT customer_sk FROM store_agg
  ),

  max_return AS (
    SELECT MAX(total_return_amt) AS max_return_amt FROM customer_returns
  )

SELECT
  cr.return_intensity,
  ib.ib_income_band_sk,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  COUNT(DISTINCT cr.c_customer_sk) AS distinct_customers,
  SUM(cr.total_net_loss) AS sum_net_loss,
  AVG(cr.total_return_amt) AS avg_return_amt,
  CASE
    WHEN AVG(cr.total_return_amt) > (SELECT max_return_amt FROM max_return) / 2 THEN 'AboveHalfMax'
    ELSE 'BelowHalfMax'
  END AS return_category
FROM customer_returns cr
JOIN income_band ib ON cr.ib_income_band_sk = ib.ib_income_band_sk
WHERE cr.return_intensity = 'Heavy'
  AND cr.warehouse_inventory_on_hand > 0
  AND cr.total_return_amt > 100
  AND cr.total_return_cnt >= 3
  AND cr.c_birth_month IN (5, 7, 9)
GROUP BY cr.return_intensity, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING SUM(cr.total_net_loss) > 1000
ORDER BY avg_return_amt DESC
LIMIT 100
