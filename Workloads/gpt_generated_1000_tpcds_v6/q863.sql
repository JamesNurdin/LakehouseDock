WITH base AS (
  SELECT
    t.t_time_sk,
    t.t_shift AS shift,
    t.t_hour,
    s.s_store_sk,
    s.s_store_id AS store_id,
    s.s_state,
    i.i_item_sk,
    i.i_category,
    i.i_current_price,
    p.p_promo_sk,
    p.p_discount_active,
    c.c_customer_sk,
    c.c_customer_id,
    hd.hd_demo_sk,
    hd.hd_income_band_sk AS income_band,
    ss.ss_net_paid,
    ws.ws_net_paid
  FROM time_dim t
  JOIN store_sales ss
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_time_sk = t.t_time_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
   AND ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
)
SELECT
  store_id,
  shift,
  AVG(total_store_sales) AS avg_store_sales,
  AVG(total_web_sales)   AS avg_web_sales
FROM (
  SELECT
    store_id,
    shift,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales
  FROM base
  WHERE shift = 'first'
    AND i_current_price > 100
    AND s_state = 'CA'
    AND p_discount_active = 'Y'
    AND income_band = 5
  GROUP BY store_id, shift

  UNION ALL

  SELECT
    store_id,
    shift,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales
  FROM base
  WHERE shift = 'second'
    AND i_current_price BETWEEN 20 AND 80
    AND s_state = 'TX'
    AND p_discount_active = 'N'
    AND income_band = 3
  GROUP BY store_id, shift
) u
GROUP BY store_id, shift
HAVING AVG(total_store_sales) > 1000
ORDER BY avg_store_sales DESC
LIMIT 100
