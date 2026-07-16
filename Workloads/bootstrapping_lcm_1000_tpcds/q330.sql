SELECT
    cr.cr_returned_date_sk,
    d_ret.d_year,
    d_ret.d_month_seq,
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cr.cr_net_loss,
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_net_profit,
    s.s_store_name,
    s.s_market_desc,
    (cs.cs_net_profit - cr.cr_net_loss + ws.ws_net_profit) AS total_profit,
    (cs.cs_quantity + cr.cr_return_quantity + ws.ws_quantity) AS total_quantity
FROM catalog_returns cr
INNER JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
INNER JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
INNER JOIN date_dim d_cs_sold
    ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
INNER JOIN date_dim d_cs_ship
    ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
INNER JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ret.d_date_sk
INNER JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
ORDER BY total_profit DESC
LIMIT 100
