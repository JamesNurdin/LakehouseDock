WITH yearly_avg AS (
    SELECT AVG(yearly_net_loss) AS avg_yearly_net_loss
    FROM (
        SELECT d.d_year AS yr, SUM(wr2.wr_net_loss) AS yearly_net_loss
        FROM web_returns wr2
        JOIN date_dim d ON wr2.wr_returned_date_sk = d.d_date_sk
        GROUP BY d.d_year
    ) y
)
SELECT
    d_ret.d_year AS year,
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    MIN(wr.wr_return_quantity) AS min_return_qty,
    MAX(ws.ws_net_profit) AS max_net_profit
FROM web_sales ws
JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE d_ret.d_year = 2001
  AND cd.cd_gender = 'F'
  AND cd.cd_marital_status = 'M'
  AND cd.cd_purchase_estimate >= 6000
  AND wr.wr_return_quantity > 1
  AND wr.wr_return_amt > 100.00
  AND ws.ws_coupon_amt < 200.00
  AND d_ret.d_holiday = 'N'
GROUP BY d_ret.d_year, cd.cd_gender, cd.cd_marital_status
HAVING SUM(wr.wr_net_loss) > (SELECT avg_yearly_net_loss FROM yearly_avg)
ORDER BY total_net_loss DESC
