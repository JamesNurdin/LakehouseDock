WITH item_sample AS (
    SELECT i_item_sk,
           i_item_id,
           i_current_price,
           i_rec_start_date
    FROM   item TABLESAMPLE BERNOULLI (10)
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    i.i_item_id,
    i.i_current_price,
    c.c_customer_id,
    c.c_preferred_cust_flag,
    t.t_hour,
    p.p_promo_id,
    /* correlated scalar subquery: total store‑return amount for the same item & customer */
    (SELECT SUM(sr.sr_return_amt)
       FROM store_returns sr
      WHERE sr.sr_item_sk = ws.ws_item_sk
        AND sr.sr_customer_sk = ws.ws_bill_customer_sk) AS total_store_return_amt,
    /* rank customers by profit within each web site */
    RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_profit DESC) AS site_profit_rank,
    v.threshold
FROM   web_sales ws
FULL   OUTER JOIN promotion p
       ON ws.ws_promo_sk = p.p_promo_sk
INNER  JOIN web_site w
       ON ws.ws_web_site_sk = w.web_site_sk
INNER  JOIN item_sample i
       ON ws.ws_item_sk = i.i_item_sk
INNER  JOIN customer c
       ON ws.ws_bill_customer_sk = c.c_customer_sk
INNER  JOIN time_dim t
       ON ws.ws_sold_time_sk = t.t_time_sk
LEFT   JOIN store_returns sr
       ON sr.sr_item_sk = i.i_item_sk
      AND sr.sr_return_time_sk = t.t_time_sk
      AND sr.sr_customer_sk = c.c_customer_sk
LEFT   JOIN catalog_returns cr
       ON cr.cr_item_sk = i.i_item_sk
      AND cr.cr_returned_time_sk = t.t_time_sk
      AND cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT   JOIN catalog_page cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
CROSS  JOIN (VALUES (1), (2), (3), (4), (5)) AS v(threshold)
WHERE  ws.ws_quantity > 5
  AND  ws.ws_net_profit > 0
  AND  i.i_current_price BETWEEN 100 AND 1000
  AND  p.p_channel_dmail = 'Y'
  AND  t.t_hour BETWEEN 8 AND 18
  AND  c.c_preferred_cust_flag = 'Y'
  AND  i.i_rec_start_date >= DATE '2000-01-01'
ORDER  BY ws.ws_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
