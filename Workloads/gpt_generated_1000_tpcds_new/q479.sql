WITH
sampled_store_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
order_numbers_to_exclude AS (
    SELECT cr_order_number AS order_number
    FROM catalog_returns
    WHERE cr_return_amount > 0
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_quantity > 0
)
SELECT
    ss.ss_ticket_number,
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    s.s_state,
    w.w_warehouse_name,
    r.r_reason_desc,
    td.t_hour,
    wp.wp_url,
    ss.ss_quantity,
    ss.ss_net_paid,
    (
        SELECT SUM(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
    ) AS total_web_net_paid_for_item,
    RANK() OVER (PARTITION BY s.s_store_sk ORDER BY ss.ss_net_paid DESC) AS sales_rank
FROM sampled_store_sales ss
JOIN time_dim td
  ON ss.ss_sold_time_sk = td.t_time_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
 AND cr.cr_returned_time_sk = td.t_time_sk
LEFT JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_sold_time_sk = td.t_time_sk
LEFT JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE i.i_current_price > 20
  AND s.s_state = 'CA'
  AND r.r_reason_id = 'AAAAAAAAABAAAAAA'
  AND td.t_hour BETWEEN 9 AND 17
  AND ss.ss_ticket_number NOT IN (SELECT order_number FROM order_numbers_to_exclude)
ORDER BY sales_rank, ss.ss_ticket_number
OFFSET 0
LIMIT 100
