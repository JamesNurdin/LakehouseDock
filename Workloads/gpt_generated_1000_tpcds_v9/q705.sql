WITH distinct_pages AS (
    SELECT DISTINCT wp_web_page_sk, wp_url
    FROM web_page
    WHERE wp_max_ad_count >= 2
      AND wp_rec_start_date >= DATE '1999-01-01'
)
SELECT
    td_sold.t_hour,
    dp.wp_url,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(ws.ws_quantity) AS min_quantity,
    MAX(ws.ws_quantity) AS max_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_tax) AS avg_return_tax
FROM web_sales ws
JOIN time_dim td_sold
  ON ws.ws_sold_time_sk = td_sold.t_time_sk
JOIN distinct_pages dp
  ON ws.ws_web_page_sk = dp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_item_sk = ws.ws_item_sk
 AND wr.wr_order_number = ws.ws_order_number
 AND wr.wr_web_page_sk = dp.wp_web_page_sk
JOIN time_dim td_return
  ON wr.wr_returned_time_sk = td_return.t_time_sk
WHERE td_sold.t_hour BETWEEN 4 AND 10
  AND td_sold.t_time = 5
  AND ws.ws_bill_cdemo_sk = 1690525
  AND ws.ws_ext_list_price > 1000
GROUP BY td_sold.t_hour, dp.wp_url
ORDER BY total_net_paid DESC
LIMIT 100
