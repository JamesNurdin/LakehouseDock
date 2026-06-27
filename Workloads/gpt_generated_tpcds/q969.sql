WITH sales AS (
    SELECT
        t.t_hour AS sale_hour,
        cd.cd_gender AS gender,
        ss.ss_net_profit AS net_profit,
        ss.ss_ticket_number AS ticket_number,
        ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_hour BETWEEN 8 AND 20
),
returns AS (
    SELECT
        sr.sr_ticket_number AS ticket_number,
        sr.sr_item_sk AS item_sk,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
)
SELECT
    s.sale_hour,
    s.gender,
    SUM(s.net_profit) AS total_sales_net_profit,
    COALESCE(SUM(r.net_loss), 0) AS total_returns_net_loss,
    SUM(s.net_profit) - COALESCE(SUM(r.net_loss), 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN returns r
    ON s.ticket_number = r.ticket_number
    AND s.item_sk = r.item_sk
GROUP BY s.sale_hour, s.gender
ORDER BY s.sale_hour, s.gender
