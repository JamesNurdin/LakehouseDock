WITH
  cr_base AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_net_loss,
      d_ret.d_year,
      w_cr.w_country,
      r_cr.r_reason_desc,
      c_ref.c_customer_id,
      cd_ref.cd_gender
    FROM catalog_returns cr
    JOIN date_dim d_ret        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c_ref        ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN warehouse w_cr        ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    JOIN reason r_cr           ON cr.cr_reason_sk = r_cr.r_reason_sk
    WHERE EXISTS (
            SELECT 1
            FROM customer_demographics cd_chk
            WHERE cd_chk.cd_gender = 'M'
              AND cd_chk.cd_demo_sk = cr.cr_refunded_cdemo_sk
          )
      AND NOT EXISTS (
            SELECT 1
            FROM reason r_chk
            WHERE r_chk.r_reason_id = 'Cancelled'
              AND r_chk.r_reason_sk = cr.cr_reason_sk
          )
      AND cr.cr_return_amount > 0
  ),
  wr_base AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      wr.wr_net_loss,
      d_ret2.d_year,
      w_ws.w_country,
      r_wr.r_reason_desc,
      c_ref2.c_customer_id,
      cd_ref2.cd_gender,
      ws.ws_net_profit
    FROM web_returns wr
    FULL OUTER JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_ret2        ON wr.wr_returned_date_sk = d_ret2.d_date_sk
    JOIN customer c_ref2        ON wr.wr_refunded_customer_sk = c_ref2.c_customer_sk
    JOIN customer_demographics cd_ref2 ON wr.wr_refunded_cdemo_sk = cd_ref2.cd_demo_sk
    JOIN reason r_wr           ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN warehouse w_ws        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    WHERE EXISTS (
            SELECT 1
            FROM reason r_chk2
            WHERE r_chk2.r_reason_desc = 'Defective'
              AND r_chk2.r_reason_sk = wr.wr_reason_sk
          )
      AND NOT EXISTS (
            SELECT 1
            FROM customer_demographics cd_chk2
            WHERE cd_chk2.cd_credit_rating = 'Poor'
              AND cd_chk2.cd_demo_sk = wr.wr_refunded_cdemo_sk
          )
      AND wr.wr_return_amt > 0
  )
SELECT
  year,
  country,
  reason_desc,
  SUM(total_amount) AS sum_total_amount,
  SUM(total_loss)   AS sum_total_loss,
  RANK() OVER (ORDER BY SUM(total_amount) DESC) AS amount_rank
FROM (
  SELECT
    d_year AS year,
    w_country AS country,
    r_reason_desc AS reason_desc,
    cr_return_amount AS total_amount,
    cr_net_loss     AS total_loss
  FROM cr_base
  UNION DISTINCT
  SELECT
    d_year,
    w_country,
    r_reason_desc,
    wr_return_amt,
    wr_net_loss
  FROM wr_base
) u
GROUP BY CUBE (year, country, reason_desc)
HAVING SUM(total_amount) > 0
ORDER BY sum_total_amount DESC
LIMIT 100
