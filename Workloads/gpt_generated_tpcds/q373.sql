WITH store_channel AS (
    SELECT
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_net_profit - COALESCE(sr.sr_net_loss, 0)) AS net_profit
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN store_returns sr
      ON ss.ss_item_sk = sr.sr_item_sk
     AND ss.ss_ticket_number = sr.sr_ticket_number
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_category, p.p_promo_name
),
catalog_channel AS (
    SELECT
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_profit - COALESCE(cr.cr_net_loss, 0)) AS net_profit
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr
      ON cs.cs_item_sk = cr.cr_item_sk
     AND cs.cs_order_number = cr.cr_order_number
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_category, p.p_promo_name
),
web_channel AS (
    SELECT
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        SUM(ws.ws_net_profit - COALESCE(wr.wr_net_loss, 0)) AS net_profit
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr
      ON ws.ws_item_sk = wr.wr_item_sk
     AND ws.ws_order_number = wr.wr_order_number
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_category, p.p_promo_name
)
SELECT
    category,
    promo_name,
    SUM(net_profit) AS total_net_profit
FROM (
    SELECT * FROM store_channel
    UNION ALL
    SELECT * FROM catalog_channel
    UNION ALL
    SELECT * FROM web_channel
) combined
GROUP BY category, promo_name
ORDER BY total_net_profit DESC
LIMIT 20
