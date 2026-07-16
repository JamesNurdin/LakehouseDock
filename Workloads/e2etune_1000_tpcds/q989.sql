WITH sales_agg AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_cdemo_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451555
),
returns_agg AS (
    SELECT
        sr.sr_return_time_sk,
        sr.sr_cdemo_sk,
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2451545 AND 2451555
)
SELECT
    t.t_hour,
    cd.cd_gender,
    SUM(sa.ss_net_profit) AS total_sales_profit,
    SUM(COALESCE(ra.sr_net_loss, 0)) AS total_return_loss,
    SUM(sa.ss_net_profit) - SUM(COALESCE(ra.sr_net_loss, 0)) AS net_profit,
    COUNT(DISTINCT sa.ss_ticket_number) AS total_transactions,
    RANK() OVER (ORDER BY SUM(sa.ss_net_profit) - SUM(COALESCE(ra.sr_net_loss, 0)) DESC) AS profit_rank
FROM sales_agg sa
JOIN time_dim t
    ON sa.ss_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd
    ON sa.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN returns_agg ra
    ON sa.ss_ticket_number = ra.sr_ticket_number
   AND sa.ss_item_sk = ra.sr_item_sk
GROUP BY t.t_hour, cd.cd_gender
HAVING SUM(sa.ss_net_profit) > 0
ORDER BY net_profit DESC
LIMIT 10
