WITH sales_agg AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales_net,
        COUNT(*) AS sales_cnt
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT
    we.web_city,
    we.web_market_manager,
    d_sold.d_year,
    p.p_promo_name,
    s.s_store_name,
    cc.cc_name,
    wp.wp_image_count,
    SUM(sa.total_sales_net) AS sum_sales_net,
    SUM(sa.sales_cnt) AS total_sales_cnt,
    SUM(wr.wr_return_amt) AS sum_return_amt,
    COUNT(wr.wr_return_amt) AS total_return_cnt
FROM sales_agg sa
JOIN web_sales ws
  ON sa.ws_item_sk = ws.ws_item_sk
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
 AND ws.ws_item_sk = wr.wr_item_sk
JOIN date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN call_center cc
  ON cc.cc_closed_date_sk = d_return.d_date_sk
GROUP BY
    we.web_city,
    we.web_market_manager,
    d_sold.d_year,
    p.p_promo_name,
    s.s_store_name,
    cc.cc_name,
    wp.wp_image_count
HAVING SUM(sa.total_sales_net) > 10000
ORDER BY sum_sales_net DESC
LIMIT 100
