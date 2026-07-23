WITH base_stats AS (
  SELECT
    S.s_store_name,
    DD.d_year,
    I.i_category,
    SUM(WS.ws_net_paid) AS total_sales,
    SUM(CR.cr_return_amount) AS total_returns,
    SUM(SR.sr_return_quantity * I.i_current_price) AS total_return_qty_amount,
    SUM(P.p_cost) AS total_promo_cost
  FROM store_returns SR
  JOIN date_dim DD ON SR.sr_returned_date_sk = DD.d_date_sk
  JOIN time_dim TD ON SR.sr_return_time_sk = TD.t_time_sk
  JOIN item I ON SR.sr_item_sk = I.i_item_sk
  JOIN household_demographics HD ON SR.sr_hdemo_sk = HD.hd_demo_sk
  JOIN customer_address CA ON SR.sr_addr_sk = CA.ca_address_sk
  JOIN store S ON SR.sr_store_sk = S.s_store_sk
  JOIN reason R ON SR.sr_reason_sk = R.r_reason_sk
  JOIN catalog_returns CR ON CR.cr_returned_date_sk = DD.d_date_sk
  JOIN ship_mode SM ON CR.cr_ship_mode_sk = SM.sm_ship_mode_sk
  JOIN warehouse W ON CR.cr_warehouse_sk = W.w_warehouse_sk
  JOIN web_sales WS ON WS.ws_sold_date_sk = DD.d_date_sk AND WS.ws_item_sk = I.i_item_sk
  JOIN web_page WP ON WS.ws_web_page_sk = WP.wp_web_page_sk
  JOIN web_site WEB ON WS.ws_web_site_sk = WEB.web_site_sk
  JOIN promotion P ON WS.ws_promo_sk = P.p_promo_sk
  WHERE
    DD.d_year = 2001
    AND I.i_category = 'Electronics'
    AND SM.sm_type = 'AIR'
    AND P.p_channel_email = 'Y'
    AND CA.ca_state = 'CA'
    AND TD.t_hour BETWEEN 8 AND 17
  GROUP BY
    S.s_store_name,
    DD.d_year,
    I.i_category
)
SELECT
  d_year,
  i_category,
  AVG(total_sales) AS avg_sales,
  AVG(total_sales - (total_returns + total_return_qty_amount + total_promo_cost)) AS avg_net_profit,
  COUNT(*) AS store_count
FROM (
  SELECT
    s_store_name,
    d_year,
    i_category,
    total_sales,
    total_returns,
    total_return_qty_amount,
    total_promo_cost,
    (total_sales - (total_returns + total_return_qty_amount + total_promo_cost)) AS net_profit
  FROM base_stats
  WHERE total_sales > 1000
) sub
WHERE net_profit > 0
GROUP BY d_year, i_category
HAVING AVG(total_sales) > 5000
ORDER BY avg_net_profit DESC
LIMIT 100
