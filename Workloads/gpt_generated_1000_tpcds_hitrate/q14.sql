WITH agg_ws AS (
    SELECT
        ws_bill_customer_sk,
        array_agg(ws_item_sk) AS items_arr,
        SUM(ws_net_paid) AS total_paid,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_ship_mode_sk = 5
      AND ws_net_paid_inc_ship_tax > 500
      AND ws_bill_addr_sk = 5240907
    GROUP BY ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_last_name,
    agg_ws.total_paid,
    agg_ws.total_discount,
    agg_ws.sales_cnt,
    COUNT(item) AS item_count,
    MIN(item) AS min_item_sk,
    MAX(item) AS max_item_sk
FROM agg_ws
JOIN customer c
    ON agg_ws.ws_bill_customer_sk = c.c_customer_sk
CROSS JOIN UNNEST(agg_ws.items_arr) AS t(item)
WHERE c.c_last_name = 'Bolden'
  AND c.c_current_hdemo_sk = 4205
  AND agg_ws.total_paid > 1000
GROUP BY c.c_customer_id, c.c_last_name, agg_ws.total_paid, agg_ws.total_discount, agg_ws.sales_cnt
ORDER BY agg_ws.total_paid DESC
LIMIT 100
