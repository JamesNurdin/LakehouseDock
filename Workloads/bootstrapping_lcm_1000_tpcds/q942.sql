SELECT
    d_ret.d_year,
    CASE WHEN d_ret.d_moy <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    cr.cr_item_sk,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT s.s_store_sk) AS closed_store_cnt,
    AVG(date_diff('day', d_ret.d_date, d_ship.d_date)) AS avg_ship_delay_days,
    CASE
        WHEN SUM(ws.ws_net_paid) = 0 THEN NULL
        ELSE SUM(cr.cr_return_amount) / SUM(ws.ws_net_paid)
    END AS return_to_sales_ratio,
    SUM(CASE WHEN ws.ws_net_profit > 0 THEN ws.ws_net_profit ELSE 0 END) -
    SUM(CASE WHEN cr.cr_net_loss IS NOT NULL THEN cr.cr_net_loss ELSE 0 END) AS net_profit_loss_diff
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d_ret.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year >= 2000
GROUP BY
    d_ret.d_year,
    CASE WHEN d_ret.d_moy <= 6 THEN 'H1' ELSE 'H2' END,
    cr.cr_item_sk
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY d_ret.d_year DESC, total_return_amount DESC
LIMIT 100
