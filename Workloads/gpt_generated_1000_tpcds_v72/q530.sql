SELECT
    ws.web_name,
    i.i_category,
    d_ret.d_year,
    COUNT(DISTINCT wr.wr_order_number) AS total_returns,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty
FROM
    web_returns wr
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_refund
    ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
JOIN household_demographics hd_refund
    ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN customer c_return
    ON wr.wr_returning_customer_sk = c_return.c_customer_sk
JOIN household_demographics hd_return
    ON wr.wr_returning_hdemo_sk = hd_return.hd_demo_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_close
    ON ws.web_close_date_sk = d_close.d_date_sk
JOIN household_demographics hd_current
    ON c_refund.c_current_hdemo_sk = hd_current.hd_demo_sk
JOIN date_dim d_ship
    ON c_refund.c_first_shipto_date_sk = d_ship.d_date_sk
WHERE
    d_ret.d_year BETWEEN 2000 AND 2005
    AND i.i_class = 'scanners'
    AND hd_current.hd_vehicle_count >= 2
    AND EXISTS (
        SELECT 1
        FROM web_returns wr3
        WHERE wr3.wr_item_sk = i.i_item_sk
          AND wr3.wr_net_loss > 200
    )
GROUP BY
    ws.web_name,
    i.i_category,
    d_ret.d_year
HAVING
    SUM(wr.wr_net_loss) > 1000
ORDER BY
    total_net_loss DESC
LIMIT 100
