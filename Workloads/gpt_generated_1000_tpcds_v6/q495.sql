SELECT
    c.c_customer_id,
    d.d_year,
    ib.ib_income_band_sk,
    SUM(sr.sr_net_loss) AS total_store_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
    MIN(ws.ws_net_paid) AS min_net_paid,
    MAX(ws.ws_net_paid) AS max_net_paid
FROM store_returns sr
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_item_sk = ws.ws_item_sk
  AND wr.wr_order_number = ws.ws_order_number
WHERE
    d.d_year = 2001
    AND c.c_birth_country IN ('BURKINA FASO', 'BAHAMAS')
    AND ib.ib_lower_bound >= 50000
    AND sr.sr_return_quantity > 2
    AND ws.ws_coupon_amt BETWEEN 50 AND 200
    AND EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = sr.sr_reason_sk
          AND r.r_reason_desc = 'Customer Not Satisfied'
    )
GROUP BY
    c.c_customer_id,
    d.d_year,
    ib.ib_income_band_sk
HAVING
    SUM(sr.sr_net_loss) > 1000
    AND SUM(ws.ws_net_profit) > 500
ORDER BY total_store_loss DESC
LIMIT 100
