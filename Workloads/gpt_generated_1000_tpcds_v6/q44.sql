WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        SUM(ws.ws_net_profit)               AS order_net_profit,
        SUM(ws.ws_ext_sales_price)           AS order_sales_amount,
        COUNT(*)                             AS line_item_cnt
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN household_demographics hd_bill
      ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
      ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
      ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE d_sold.d_year = 2001
      AND t_sold.t_hour BETWEEN 12 AND 18
      AND wp.wp_type = 'article'
    GROUP BY
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk
)
SELECT
    wsit.web_name                              AS website,
    wp.wp_type                                 AS page_type,
    ib.ib_lower_bound                          AS income_lower,
    ib.ib_upper_bound                          AS income_upper,
    COUNT(DISTINCT sa.ws_order_number)         AS orders,
    SUM(sa.order_net_profit)                   AS total_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0))           AS total_return_loss,
    AVG(sa.order_sales_amount)                 AS avg_sales_amount,
    (
        SELECT AVG(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = wsit.web_site_sk
          AND ws2.ws_sold_date_sk IN (
                SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_year = 2001
          )
    )                                          AS site_avg_net_paid
FROM sales_agg sa
JOIN date_dim d_sold
  ON sa.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON sa.ws_sold_time_sk = t_sold.t_time_sk
JOIN web_page wp
  ON sa.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit
  ON sa.ws_web_site_sk = wsit.web_site_sk
JOIN household_demographics hd_bill
  ON sa.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = sa.ws_order_number
     AND wr.wr_returned_date_sk = d_sold.d_date_sk
     AND wr.wr_returned_time_sk = t_sold.t_time_sk
     AND wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%color%'
GROUP BY
    wsit.web_name,
    wp.wp_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wsit.web_site_sk
ORDER BY total_net_profit DESC
LIMIT 100
