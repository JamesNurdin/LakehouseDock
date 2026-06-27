WITH
    store AS (
        SELECT
            t.t_hour AS hour_of_day,
            SUM(ss.ss_net_paid)                         AS sales_amount,
            SUM(ss.ss_net_profit)                       AS profit,
            SUM(COALESCE(sr.sr_net_loss, 0))            AS return_loss
        FROM store_sales ss
        LEFT JOIN store_returns sr
            ON ss.ss_item_sk = sr.sr_item_sk
           AND ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        GROUP BY t.t_hour
    ),
    catalog AS (
        SELECT
            t.t_hour AS hour_of_day,
            SUM(cs.cs_net_paid)                         AS sales_amount,
            SUM(cs.cs_net_profit)                       AS profit,
            SUM(COALESCE(cr.cr_net_loss, 0))            AS return_loss
        FROM catalog_sales cs
        LEFT JOIN catalog_returns cr
            ON cs.cs_item_sk = cr.cr_item_sk
           AND cs.cs_order_number = cr.cr_order_number
        LEFT JOIN time_dim t
            ON cs.cs_sold_time_sk = t.t_time_sk
        GROUP BY t.t_hour
    ),
    web AS (
        SELECT
            t.t_hour AS hour_of_day,
            SUM(ws.ws_net_paid)                         AS sales_amount,
            SUM(ws.ws_net_profit)                       AS profit,
            SUM(COALESCE(wr.wr_net_loss, 0))            AS return_loss
        FROM web_sales ws
        LEFT JOIN web_returns wr
            ON ws.ws_item_sk = wr.wr_item_sk
           AND ws.ws_order_number = wr.wr_order_number
        LEFT JOIN time_dim t
            ON ws.ws_sold_time_sk = t.t_time_sk
        GROUP BY t.t_hour
    )
SELECT
    COALESCE(s.hour_of_day, c.hour_of_day, w.hour_of_day)                     AS hour_of_day,
    COALESCE(s.sales_amount, 0) + COALESCE(c.sales_amount, 0) + COALESCE(w.sales_amount, 0) AS total_sales_amount,
    COALESCE(s.profit, 0) + COALESCE(c.profit, 0) + COALESCE(w.profit, 0)       AS total_profit,
    COALESCE(s.return_loss, 0) + COALESCE(c.return_loss, 0) + COALESCE(w.return_loss, 0) AS total_return_loss,
    (COALESCE(s.sales_amount, 0) + COALESCE(c.sales_amount, 0) + COALESCE(w.sales_amount, 0))
    - (COALESCE(s.return_loss, 0) + COALESCE(c.return_loss, 0) + COALESCE(w.return_loss, 0)) AS net_sales_after_returns
FROM store   s
FULL OUTER JOIN catalog c ON s.hour_of_day = c.hour_of_day
FULL OUTER JOIN web    w ON COALESCE(s.hour_of_day, c.hour_of_day) = w.hour_of_day
ORDER BY hour_of_day
