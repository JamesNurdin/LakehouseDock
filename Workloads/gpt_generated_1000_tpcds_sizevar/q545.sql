WITH
  catalog_detail AS (
    SELECT
      cr.cr_item_sk,
      d.d_year,
      i.i_category,
      i.i_category_id,
      cr.cr_return_amount,
      cr.cr_net_loss,
      CASE WHEN cr.cr_net_loss > 0 THEN 'LOSS' ELSE 'PROFIT' END AS loss_flag,
      w.w_state AS warehouse_state,
      s.s_state AS store_state,
      ca.ca_state AS address_state
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON d.d_date_sk = s.s_closed_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND i.i_category_id IN (3, 5, 7)
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk BETWEEN 1 AND 5
      AND w.w_state = 'CA'
      AND s.s_state = 'CA'
      AND ca.ca_state = 'CA'
  ),
  web_detail AS (
    SELECT
      wr.wr_item_sk AS item_sk,
      d2.d_year,
      i2.i_category,
      i2.i_category_id,
      wr.wr_return_amt,
      wr.wr_net_loss,
      CASE WHEN wr.wr_net_loss > 0 THEN 'LOSS' ELSE 'PROFIT' END AS loss_flag,
      s2.s_state AS store_state,
      ca2.ca_state AS address_state
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    JOIN customer c2 ON wr.wr_refunded_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2 ON wr.wr_refunded_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2 ON wr.wr_refunded_addr_sk = ca2.ca_address_sk
    JOIN store s2 ON d2.d_date_sk = s2.s_closed_date_sk
    WHERE d2.d_year BETWEEN 1998 AND 2000
      AND i2.i_category_id IN (3, 5, 7)
      AND cd2.cd_gender = 'M'
      AND hd2.hd_income_band_sk BETWEEN 1 AND 5
      AND s2.s_state = 'CA'
      AND ca2.ca_state = 'CA'
  ),
  combined AS (
    SELECT
      COALESCE(cd.cr_item_sk, wd.item_sk) AS item_sk,
      COALESCE(cd.d_year, wd.d_year) AS year,
      cd.cr_return_amount,
      wd.wr_return_amt,
      cd.cr_net_loss,
      wd.wr_net_loss,
      cd.loss_flag AS catalog_loss_flag,
      wd.loss_flag AS web_loss_flag,
      cd.store_state AS catalog_store_state,
      wd.store_state AS web_store_state,
      cd.warehouse_state,
      cd.address_state AS catalog_address_state,
      wd.address_state AS web_address_state
    FROM catalog_detail cd
    FULL OUTER JOIN web_detail wd
      ON cd.cr_item_sk = wd.item_sk AND cd.d_year = wd.d_year
  ),
  catalog_only_items AS (
    SELECT cr_item_sk FROM catalog_returns
    EXCEPT
    SELECT wr_item_sk FROM web_returns
  ),
  final_agg AS (
    SELECT
      c.item_sk,
      c.year,
      SUM(COALESCE(c.cr_return_amount, 0) + COALESCE(c.wr_return_amt, 0)) AS total_return_amount,
      SUM(COALESCE(c.cr_net_loss, 0) + COALESCE(c.wr_net_loss, 0)) AS total_net_loss,
      COUNT(*) FILTER (WHERE c.catalog_loss_flag = 'LOSS') AS catalog_loss_cnt,
      COUNT(*) FILTER (WHERE c.web_loss_flag = 'LOSS') AS web_loss_cnt,
      ROW_NUMBER() OVER (PARTITION BY c.year ORDER BY SUM(COALESCE(c.cr_return_amount, 0) + COALESCE(c.wr_return_amt, 0)) DESC) AS rn,
      (SELECT MAX(cr_return_amount) FROM catalog_returns) AS max_catalog_return
    FROM combined c
    WHERE c.item_sk IN (SELECT cr_item_sk FROM catalog_only_items)
    GROUP BY c.item_sk, c.year
    HAVING SUM(COALESCE(c.cr_return_amount, 0) + COALESCE(c.wr_return_amt, 0)) > 1000
  )
SELECT *
FROM final_agg
ORDER BY year DESC, total_return_amount DESC
LIMIT 100
