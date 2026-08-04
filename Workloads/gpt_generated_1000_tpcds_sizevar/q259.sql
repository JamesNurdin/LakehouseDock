WITH ws_agg AS (
   SELECT
       ws.ws_item_sk,
       ws.ws_sold_date_sk,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_quantity)        AS total_qty
   FROM web_sales ws
   WHERE ws.ws_sold_date_sk IN (
       SELECT d_date_sk
       FROM date_dim
       WHERE d_year = 2001               -- filter 1
         AND d_month_seq BETWEEN 1 AND 12 -- filter 2
         AND d_day_name = 'Monday'        -- filter 3
   )
   GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_date,
    ws_agg.total_sales,
    ws_agg.total_qty,
    w.w_warehouse_name,
    wp.wp_type,
    web_s.web_name,
    p.p_promo_name,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ws_agg.total_sales DESC) AS sales_rank,
    (
        SELECT COALESCE(SUM(sr.sr_return_quantity), 0)
        FROM store_returns sr
        WHERE sr.sr_item_sk = i.i_item_sk
          AND sr.sr_returned_date_sk = d.d_date_sk
    ) AS total_return_qty,
    (
        SELECT COUNT(*)
        FROM reason r_sub
        WHERE r_sub.r_reason_sk = sr_ret.sr_reason_sk
    ) AS reason_match_count
FROM ws_agg
JOIN item i
  ON ws_agg.ws_item_sk = i.i_item_sk
JOIN date_dim d
  ON ws_agg.ws_sold_date_sk = d.d_date_sk
JOIN web_sales ws2
  ON ws_agg.ws_item_sk = ws2.ws_item_sk
 AND ws_agg.ws_sold_date_sk = ws2.ws_sold_date_sk
JOIN warehouse w
  ON ws2.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws2.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web_s
  ON ws2.ws_web_site_sk = web_s.web_site_sk
JOIN promotion p
  ON ws2.ws_promo_sk = p.p_promo_sk
 AND p.p_item_sk = i.i_item_sk
 AND p.p_start_date_sk = d.d_date_sk
LEFT JOIN store_returns sr_ret
  ON sr_ret.sr_item_sk = i.i_item_sk
 AND sr_ret.sr_returned_date_sk = d.d_date_sk
LEFT JOIN customer_address ca
  ON sr_ret.sr_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
  ON sr_ret.sr_cdemo_sk = cd.cd_demo_sk
LEFT JOIN reason r
  ON sr_ret.sr_reason_sk = r.r_reason_sk
WHERE i.i_color = 'pink'                 -- filter 4
  AND i.i_units = 'Each'                 -- filter 5
  AND w.w_state = 'CA'                   -- filter 6
  AND web_s.web_country = 'United States'-- filter 7
  AND p.p_discount_active = 'Y'          -- filter 8
ORDER BY ws_agg.total_sales DESC
LIMIT 100
