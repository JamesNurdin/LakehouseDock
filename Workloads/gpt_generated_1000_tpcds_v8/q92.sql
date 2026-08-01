WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand,
           COUNT(DISTINCT inv_warehouse_sk) AS warehouse_cnt
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    td.t_hour,
    td.t_minute,
    i.i_item_id,
    i.i_product_name,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_net_profit,
    ia.total_qty_on_hand,
    cd_bill.cd_gender,
    wp.wp_url,
    RANK() OVER (PARTITION BY td.t_hour ORDER BY ws.ws_net_profit DESC) AS profit_rank_hour,
    ROW_NUMBER() OVER (PARTITION BY td.t_hour ORDER BY ws.ws_sold_date_sk NULLS LAST) AS row_seq
FROM web_sales ws
RIGHT OUTER JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN inv_agg ia
    ON ia.inv_item_sk = i.i_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_return_time_sk = td.t_time_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_time_sk = td.t_time_sk
WHERE
    td.t_minute IN (0, 5, 1)
    AND i.i_brand_id = 123
    AND ia.total_qty_on_hand > 500
    AND ws.ws_quantity > 1
    AND cd_bill.cd_gender = 'F'
    AND wp.wp_type = 'Content'
    AND sr.sr_return_quantity IS NOT NULL
ORDER BY td.t_hour, profit_rank_hour
LIMIT 100
