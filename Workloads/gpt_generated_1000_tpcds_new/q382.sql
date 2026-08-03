WITH ws_summary AS (
    SELECT
        ws_order_number,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_item_sk,
        ws_bill_customer_sk,
        ws_promo_sk,
        ws_web_page_sk,
        ws_quantity,
        ws_ext_sales_price,
        ws_net_profit
    FROM web_sales
    WHERE ws_quantity > 0
)
SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    ca.ca_state,
    cc.cc_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_quantity) AS avg_quantity
FROM ws_summary ws
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_category_id IN (3, 5)
  AND p.p_discount_active = 'Y'
  AND cc.cc_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = ws.ws_item_sk
          AND sr2.sr_returned_date_sk = ws.ws_sold_date_sk
          AND sr2.sr_return_amt > 0
      )
GROUP BY ROLLUP (d.d_year, i.i_category, i.i_brand, p.p_promo_name, ca.ca_state, cc.cc_name)
LIMIT 100
