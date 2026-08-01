WITH
  sampled_catalog AS (
    SELECT
      cr_returned_date_sk,
      cr_returned_time_sk,
      cr_item_sk,
      cr_refunded_customer_sk,
      cr_refunded_cdemo_sk,
      cr_reason_sk,
      cr_order_number,
      cr_return_amount,
      cr_net_loss
    FROM tpcds.catalog_returns
    TABLESAMPLE BERNOULLI (10)
  ),
  sampled_web AS (
    SELECT
      wr_returned_date_sk,
      wr_returned_time_sk,
      wr_item_sk,
      wr_refunded_customer_sk,
      wr_refunded_cdemo_sk,
      wr_reason_sk,
      wr_order_number,
      wr_return_amt   AS return_amount,
      wr_net_loss
    FROM tpcds.web_returns
    TABLESAMPLE BERNOULLI (10)
  ),
  combined_returns AS (
    SELECT
      cr_order_number               AS order_number,
      cr_returned_date_sk           AS returned_date_sk,
      cr_returned_time_sk           AS returned_time_sk,
      cr_item_sk                    AS item_sk,
      cr_refunded_customer_sk       AS customer_sk,
      cr_refunded_cdemo_sk          AS cdemo_sk,
      cr_reason_sk                  AS reason_sk,
      cr_return_amount              AS return_amount,
      cr_net_loss
    FROM sampled_catalog
    UNION ALL
    SELECT
      wr_order_number,
      wr_returned_date_sk,
      wr_returned_time_sk,
      wr_item_sk,
      wr_refunded_customer_sk,
      wr_refunded_cdemo_sk,
      wr_reason_sk,
      return_amount,
      wr_net_loss
    FROM sampled_web
  ),
  order_numbers_catalog AS (
    SELECT cr_order_number AS order_number FROM tpcds.catalog_returns
  ),
  order_numbers_web AS (
    SELECT wr_order_number AS order_number FROM tpcds.web_returns
  ),
  catalog_not_in_web AS (
    SELECT order_number FROM order_numbers_catalog
    EXCEPT
    SELECT order_number FROM order_numbers_web
  ),
  catalog_not_in_web_intersect AS (
    SELECT order_number FROM catalog_not_in_web
    INTERSECT
    SELECT order_number FROM combined_returns
  ),
  aggregated AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category,
      SUM(cr.return_amount)      AS total_return_amount,
      AVG(cr.return_amount)      AS avg_return_amount,
      SUM(cr.cr_net_loss)        AS total_net_loss,
      COUNT(DISTINCT cr.order_number) AS distinct_orders,
      MIN(cr.return_amount)      AS min_return,
      MAX(cr.return_amount)      AS max_return
    FROM combined_returns cr
    JOIN tpcds.date_dim d      ON cr.returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t      ON cr.returned_time_sk = t.t_time_sk
    JOIN tpcds.item i          ON cr.item_sk = i.i_item_sk
    JOIN tpcds.customer cu    ON cr.customer_sk = cu.c_customer_sk
    JOIN tpcds.customer_demographics cd ON cr.cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.reason r       ON cr.reason_sk = r.r_reason_sk
    JOIN tpcds.promotion p    ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk = d.d_date_sk
    JOIN tpcds.store s        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND d.d_month_seq IN (1, 2, 3)
      AND i.i_units = 'Each'
      AND i.i_class_id IN (4, 9)
      AND s.s_state = 'CA'
      AND cr.return_amount > 50
      AND cr.order_number IN (SELECT order_number FROM catalog_not_in_web_intersect)
    GROUP BY GROUPING SETS (
      (d.d_year, d.d_month_seq, i.i_category),
      (d.d_year, d.d_month_seq),
      (d.d_year),
      ()
    )
  )
SELECT
  a.d_year,
  a.d_month_seq,
  a.i_category,
  a.total_return_amount,
  a.avg_return_amount,
  a.total_net_loss,
  a.distinct_orders,
  a.min_return,
  a.max_return,
  RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_return_amount DESC) AS yearly_rank
FROM aggregated a
ORDER BY a.d_year, a.d_month_seq, a.total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
