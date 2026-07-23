/* goal: Analyze catalog sales together with their returns, store sales, and demographic / date / ship‑mode dimensions.  For each sales year, ship‑mode type and customer gender, compute total net paid, total net profit, total return net loss, average sales price, overall average net profit across all catalog sales, and total store‑sales quantity.  Only keep catalog sales that have at least one return with a positive net loss (filtered via an EXISTS semi‑join). */
SELECT
    d_sold.d_year AS sale_year,
    sm_ship.sm_type AS ship_type,
    cd_bill.cd_gender AS customer_gender,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_net_profit,
    SUM(ss.ss_quantity) AS total_store_quantity
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm_ship
  ON cs.cs_ship_mode_sk = sm_ship.sm_ship_mode_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
  ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN ship_mode sm_return
  ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
JOIN customer_demographics cd_refunded
  ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_store
  ON ss.ss_sold_time_sk = t_store.t_time_sk
JOIN customer_demographics cd_store
  ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = cs.cs_order_number
      AND cr2.cr_net_loss > 0
)
GROUP BY
    d_sold.d_year,
    sm_ship.sm_type,
    cd_bill.cd_gender
ORDER BY total_net_paid DESC
LIMIT 100
