WITH aggregated_store_returns AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_ticket_cnt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IS NOT NULL
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
)
SELECT
    ws.ws_order_number,
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    s.s_store_name,
    sm.sm_type AS ship_mode_type,
    promo.p_promo_name,
    wp.wp_url,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_net_profit,
    ar.total_return_qty,
    ar.total_return_amt,
    inv_latest.inv_quantity_on_hand,
    wr.wr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ws.ws_sales_price DESC) AS sales_rank,
    SUM(ws.ws_quantity) OVER (PARTITION BY i.i_item_id ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_quantity_to_date,
    CASE WHEN ws.ws_ext_discount_amt > 0 THEN 'Discounted' ELSE 'Full Price' END AS price_type,
    (SELECT MAX(ws2.ws_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk) AS max_item_sales_price,
    (SELECT COUNT(*)
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_returned_date_sk = d.d_date_sk) AS web_return_cnt_same_day
FROM web_sales ws
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion promo
    ON ws.ws_promo_sk = promo.p_promo_sk
   AND promo.p_item_sk = i.i_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN aggregated_store_returns ar
    ON ar.sr_item_sk = i.i_item_sk
   AND ar.sr_returned_date_sk = d.d_date_sk
LEFT JOIN LATERAL (
    SELECT inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
      AND inv.inv_date_sk = d.d_date_sk
    ORDER BY inv.inv_date_sk DESC
    LIMIT 1
) inv_latest
    ON TRUE
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2020
  AND i.i_current_price > 10.00
  AND sm.sm_type = 'AIR'
ORDER BY ws.ws_sales_price DESC, d.d_date ASC
LIMIT 100
