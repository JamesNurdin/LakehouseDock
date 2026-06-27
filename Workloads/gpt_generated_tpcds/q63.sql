/*
  Analytical query: sales, returns and web‑sales metrics by hour and shift.
  Shows total quantity, net paid, profit, return quantity, net loss,
  and the return‑rate for catalog sales, together with web‑sales figures.
*/
WITH catalog_agg AS (
    SELECT
        td.t_hour,
        td.t_shift,
        SUM(cs.cs_quantity)                       AS total_quantity,
        SUM(cs.cs_net_paid_inc_tax)               AS total_net_paid,
        SUM(cs.cs_net_profit)                     AS total_profit,
        SUM(COALESCE(cr.cr_return_quantity, 0))   AS total_return_quantity,
        SUM(COALESCE(cr.cr_net_loss, 0))          AS total_net_loss
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    GROUP BY td.t_hour, td.t_shift
),
web_agg AS (
    SELECT
        td.t_hour,
        td.t_shift,
        SUM(ws.ws_quantity)        AS total_ws_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_ws_net_paid,
        SUM(ws.ws_net_profit)      AS total_ws_profit
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour, td.t_shift
)
SELECT
    c.t_hour,
    c.t_shift,
    c.total_quantity,
    c.total_net_paid,
    c.total_profit,
    c.total_return_quantity,
    c.total_net_loss,
    CASE WHEN c.total_quantity > 0
         THEN CAST(c.total_return_quantity AS DOUBLE) / c.total_quantity
         ELSE 0
    END AS return_rate,
    w.total_ws_quantity,
    w.total_ws_net_paid,
    w.total_ws_profit
FROM catalog_agg c
LEFT JOIN web_agg w
    ON c.t_hour = w.t_hour
   AND c.t_shift = w.t_shift
ORDER BY c.t_hour, c.t_shift
