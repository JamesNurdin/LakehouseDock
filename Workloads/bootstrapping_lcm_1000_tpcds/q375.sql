SELECT
    s.s_market_id,
    d_cr.d_year,
    d_cr.d_month_seq,
    SUM(ws.ws_quantity) AS total_sales_qty,
    SUM(cr.cr_return_quantity) + SUM(wr.wr_return_quantity) AS total_return_qty,
    (SUM(cr.cr_return_quantity) + SUM(wr.wr_return_quantity)) * 1.0 / NULLIF(SUM(ws.ws_quantity), 0) AS return_rate,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_return_loss,
    SUM(ws.ws_net_profit) - (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS net_gain,
    RANK() OVER (
        PARTITION BY d_cr.d_year
        ORDER BY SUM(ws.ws_net_profit) - (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) DESC
    ) AS profit_rank_by_year
FROM catalog_returns cr
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cr.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_cr.d_date_sk
JOIN web_sales ws
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
   AND ws.ws_sold_date_sk = d_cr.d_date_sk
GROUP BY s.s_market_id, d_cr.d_year, d_cr.d_month_seq
HAVING SUM(ws.ws_quantity) > 0
ORDER BY net_gain DESC
LIMIT 100
