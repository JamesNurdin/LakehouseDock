WITH cr AS (
    SELECT
        cr_order_number,
        cr_returned_date_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_net_loss,
        cr_returning_customer_sk,
        cr_ship_mode_sk
    FROM catalog_returns
    WHERE cr_return_amount > 30
      AND cr_net_loss > 0
),
wr AS (
    SELECT
        wr_order_number,
        wr_returned_date_sk,
        wr_return_quantity,
        wr_return_amt,
        wr_net_loss,
        wr_returning_customer_sk
    FROM web_returns
    WHERE wr_return_amt > 30
      AND wr_net_loss > 0
)
SELECT
    cust.c_customer_id,
    d_cr.d_year,
    sm.sm_carrier,
    s.s_store_name,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
    RANK() OVER (PARTITION BY d_cr.d_year ORDER BY (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) DESC) AS yearly_customer_rank
FROM cr
JOIN date_dim d_cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer cust
  ON cr.cr_returning_customer_sk = cust.c_customer_sk
JOIN web_returns wr
  ON wr.wr_returning_customer_sk = cust.c_customer_sk
JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_cr.d_date_sk
WHERE d_cr.d_year = 2001
  AND sm.sm_carrier = 'MSC'
  AND s.s_tax_percentage >= 0.04
GROUP BY cust.c_customer_id,
         d_cr.d_year,
         sm.sm_carrier,
         s.s_store_name
ORDER BY yearly_customer_rank,
         total_catalog_net_loss DESC
LIMIT 100
