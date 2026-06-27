WITH store_data AS (
    SELECT
        p.p_promo_id,
        t.t_hour,
        ss.ss_net_profit AS net_profit,
        COALESCE(sr.sr_net_loss, 0) AS net_loss
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
),
catalog_data AS (
    SELECT
        p.p_promo_id,
        t.t_hour,
        cs.cs_net_profit AS net_profit,
        COALESCE(cr.cr_net_loss, 0) AS net_loss
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
),
web_data AS (
    SELECT
        p.p_promo_id,
        t.t_hour,
        ws.ws_net_profit AS net_profit,
        COALESCE(wr.wr_net_loss, 0) AS net_loss
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
)
SELECT
    promo_id,
    hour_of_day,
    total_net_profit,
    total_net_loss,
    net_contribution,
    RANK() OVER (PARTITION BY hour_of_day ORDER BY net_contribution DESC) AS promo_rank_in_hour
FROM (
    SELECT
        promo_id,
        hour_of_day,
        SUM(total_net_profit) AS total_net_profit,
        SUM(total_net_loss) AS total_net_loss,
        SUM(total_net_profit) - SUM(total_net_loss) AS net_contribution
    FROM (
        SELECT p_promo_id AS promo_id, t_hour AS hour_of_day,
               net_profit AS total_net_profit,
               net_loss AS total_net_loss
        FROM store_data
        UNION ALL
        SELECT p_promo_id AS promo_id, t_hour AS hour_of_day,
               net_profit AS total_net_profit,
               net_loss AS total_net_loss
        FROM catalog_data
        UNION ALL
        SELECT p_promo_id AS promo_id, t_hour AS hour_of_day,
               net_profit AS total_net_profit,
               net_loss AS total_net_loss
        FROM web_data
    ) combined
    GROUP BY promo_id, hour_of_day
    HAVING SUM(total_net_profit) > 0
) agg
ORDER BY net_contribution DESC
LIMIT 100
