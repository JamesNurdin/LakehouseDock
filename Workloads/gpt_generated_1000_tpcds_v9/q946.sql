/*
  Goal: Summarize web return performance by year, web site, and customer income band, showing total returns, net loss, distinct refunded customers, a high/low return amount categorisation, average vehicle count from the customers' current household demographics, and the total inventory on the return date.
*/
WITH inventory_by_date AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_date_sk
)
SELECT
    d_ret.d_year,
    ws.web_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN wr.wr_return_amt > 100 THEN 'High'
        ELSE 'Low'
    END AS return_category,
    COUNT(*) AS total_returns,
    SUM(wr.wr_net_loss) AS net_loss,
    COUNT(DISTINCT cust_refunded.c_customer_id) AS distinct_refunded_customers,
    AVG(hd_current.hd_vehicle_count) AS avg_vehicle_count,
    (
        SELECT inv_sub.total_quantity_on_hand
        FROM inventory_by_date inv_sub
        WHERE inv_sub.inv_date_sk = d_ret.d_date_sk
    ) AS inventory_on_return_date
FROM web_returns wr
JOIN date_dim d_ret
  ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer cust_refunded
  ON wr.wr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN household_demographics hd_refunded
  ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer cust_returning
  ON wr.wr_returning_customer_sk = cust_returning.c_customer_sk
JOIN household_demographics hd_returning
  ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN income_band ib
  ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_ws_close
  ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN inventory inv_main
  ON inv_main.inv_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_current
  ON cust_refunded.c_current_hdemo_sk = hd_current.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory inv_check
    WHERE inv_check.inv_date_sk = d_ret.d_date_sk
      AND inv_check.inv_quantity_on_hand > 0
)
GROUP BY
    d_ret.d_year,
    ws.web_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN wr.wr_return_amt > 100 THEN 'High'
        ELSE 'Low'
    END,
    d_ret.d_date_sk
ORDER BY net_loss DESC
LIMIT 100
