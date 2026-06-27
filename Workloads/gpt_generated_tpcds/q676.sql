WITH store_sales_agg AS (
    SELECT
        i.i_brand,
        p.p_promo_id,
        t.t_hour,
        SUM(ss.ss_net_profit) AS sales_net_profit,
        COALESCE(SUM(sr.sr_net_loss), 0) AS returns_net_loss
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_brand, p.p_promo_id, t.t_hour
),
catalog_sales_agg AS (
    SELECT
        i.i_brand,
        p.p_promo_id,
        t.t_hour,
        SUM(cs.cs_net_profit) AS sales_net_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS returns_net_loss
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_brand, p.p_promo_id, t.t_hour
),
web_sales_agg AS (
    SELECT
        i.i_brand,
        p.p_promo_id,
        t.t_hour,
        SUM(ws.ws_net_profit) AS sales_net_profit,
        COALESCE(SUM(wr.wr_net_loss), 0) AS returns_net_loss
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_brand, p.p_promo_id, t.t_hour
),
combined AS (
    SELECT i_brand, p_promo_id, t_hour,
        sales_net_profit,
        returns_net_loss
    FROM store_sales_agg
    UNION ALL
    SELECT i_brand, p_promo_id, t_hour,
        sales_net_profit,
        returns_net_loss
    FROM catalog_sales_agg
    UNION ALL
    SELECT i_brand, p_promo_id, t_hour,
        sales_net_profit,
        returns_net_loss
    FROM web_sales_agg
)
SELECT
    i_brand,
    p_promo_id,
    t_hour,
    SUM(sales_net_profit) AS total_sales_net_profit,
    SUM(returns_net_loss) AS total_returns_net_loss,
    SUM(sales_net_profit) - SUM(returns_net_loss) AS net_profit_after_returns
FROM combined
GROUP BY i_brand, p_promo_id, t_hour
ORDER BY net_profit_after_returns DESC
LIMIT 100
