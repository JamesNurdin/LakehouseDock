WITH
  store_part AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_store_sk,
      sr.sr_reason_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      i.i_brand,
      i.i_category,
      i.i_current_price,
      s.s_store_name AS store_name,
      r.r_reason_desc AS reason_desc
    FROM
      store_returns sr
      JOIN item i ON sr.sr_item_sk = i.i_item_sk
      JOIN store s ON sr.sr_store_sk = s.s_store_sk
      JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
      i.i_units = 'Each'
      AND s.s_state = 'CA'
      AND sr.sr_return_amt > 10
  ),
  catalog_part AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_reason_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_net_loss,
      i.i_brand,
      i.i_category,
      i.i_current_price,
      r.r_reason_desc AS reason_desc
    FROM
      catalog_returns cr
      JOIN item i ON cr.cr_item_sk = i.i_item_sk
      JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
      i.i_manufact_id = 364
      AND cr.cr_return_amount > 100
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2451000
  ),
  web_part AS (
    SELECT
      wr.wr_item_sk,
      wr.wr_web_page_sk,
      wr.wr_reason_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_net_loss,
      i.i_brand,
      i.i_category,
      i.i_current_price,
      wp.wp_type,
      r.r_reason_desc AS reason_desc
    FROM
      web_returns wr
      JOIN item i ON wr.wr_item_sk = i.i_item_sk
      JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
      JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
      wp.wp_autogen_flag = 'N'
      AND i.i_category = 'Books'
      AND wr.wr_return_amt > 5
  ),
  full_part AS (
    SELECT
      COALESCE(sp.sr_item_sk, wp.wr_item_sk) AS item_sk,
      COALESCE(sp.store_name, 'UNKNOWN')                AS store_name,
      COALESCE(sp.reason_desc, wp.reason_desc)          AS reason_desc,
      sp.i_brand,
      sp.i_category,
      sp.i_current_price,
      wp.wp_type,
      sp.sr_return_quantity,
      sp.sr_return_amt,
      sp.sr_net_loss,
      wp.wr_return_quantity,
      wp.wr_return_amt,
      wp.wr_net_loss
    FROM
      store_part sp
      FULL OUTER JOIN web_part wp
        ON sp.sr_item_sk = wp.wr_item_sk
  )
SELECT
  fp.item_sk,
  fp.i_brand,
  fp.i_category,
  fp.i_current_price,
  fp.store_name,
  fp.wp_type,
  fp.reason_desc,
  COUNT(*)                                          AS return_rows,
  SUM(COALESCE(fp.sr_return_amt, 0) + COALESCE(fp.wr_return_amt, 0) + COALESCE(cp.cr_return_amount, 0)) AS total_return_amount,
  SUM(COALESCE(fp.sr_net_loss, 0) + COALESCE(fp.wr_net_loss, 0) + COALESCE(cp.cr_net_loss, 0))       AS total_net_loss,
  AVG(COALESCE(fp.sr_return_quantity, 0) + COALESCE(fp.wr_return_quantity, 0) + COALESCE(cp.cr_return_quantity, 0)) AS avg_return_quantity,
  CASE
    WHEN SUM(COALESCE(fp.sr_return_amt, 0) + COALESCE(fp.wr_return_amt, 0) + COALESCE(cp.cr_return_amount, 0)) >
         (SELECT AVG(cr_return_amount) FROM catalog_returns)
    THEN 'Above Avg'
    ELSE 'Below Avg'
  END                                              AS return_level
FROM
  full_part fp
  LEFT JOIN catalog_part cp ON fp.item_sk = cp.cr_item_sk
GROUP BY
  fp.item_sk,
  fp.i_brand,
  fp.i_category,
  fp.i_current_price,
  fp.store_name,
  fp.wp_type,
  fp.reason_desc
ORDER BY
  total_return_amount DESC
LIMIT 100
