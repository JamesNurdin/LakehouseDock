WITH
  store_ret AS (
    SELECT
      c.c_customer_id               AS customer_id,
      d.d_year                      AS year,
      SUM(sr.sr_net_loss)           AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 150000
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY c.c_customer_id, d.d_year
  ),
  web_ret AS (
    SELECT
      c.c_customer_id               AS customer_id,
      d.d_year                      AS year,
      SUM(wr.wr_net_loss)           AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 150000
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY c.c_customer_id, d.d_year
  ),
  combined AS (
    SELECT
      customer_id,
      year,
      total_net_loss,
      CASE WHEN total_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM (
      SELECT * FROM store_ret
      UNION ALL
      SELECT * FROM web_ret
    ) u
  )
SELECT DISTINCT
  c.customer_id,
  c.year,
  c.total_net_loss,
  c.loss_category
FROM combined c
WHERE NOT EXISTS (
  SELECT 1
  FROM catalog_sales cs
  JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
  JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
  WHERE cust.c_customer_id = c.customer_id
    AND d2.d_year = c.year
)
ORDER BY c.total_net_loss DESC, c.customer_id
LIMIT 100
