WITH agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        d_ret.d_date AS return_date,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(ws.ws_quantity) AS total_sold_qty,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT s.s_store_sk) AS num_stores_closed,
        AVG(s.s_tax_percentage) AS avg_store_tax_pct
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    GROUP BY i.i_item_sk, i.i_product_name, d_ret.d_date
)
SELECT
    a.i_item_sk,
    a.i_product_name,
    a.return_date,
    a.total_return_qty,
    a.total_return_loss,
    a.total_sold_qty,
    a.total_net_profit,
    a.num_stores_closed,
    a.avg_store_tax_pct,
    ROW_NUMBER() OVER (ORDER BY a.total_return_loss DESC) AS loss_rank
FROM agg a
ORDER BY a.total_return_loss DESC
LIMIT 100
