WITH store_agg AS (
    SELECT
        d.d_year AS year,
        p.p_promo_id AS promo_id,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year, p.p_promo_id
),
catalog_agg AS (
    SELECT
        d.d_year AS year,
        p.p_promo_id AS promo_id,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS net_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year, p.p_promo_id
),
web_agg AS (
    SELECT
        d.d_year AS year,
        p.p_promo_id AS promo_id,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS net_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year, p.p_promo_id
),
combined AS (
    SELECT year, promo_id, net_profit, net_loss FROM store_agg
    UNION ALL
    SELECT year, promo_id, net_profit, net_loss FROM catalog_agg
    UNION ALL
    SELECT year, promo_id, net_profit, net_loss FROM web_agg
)
SELECT
    combined.year,
    combined.promo_id,
    SUM(combined.net_profit) AS total_net_profit,
    SUM(combined.net_loss) AS total_net_loss,
    (SUM(combined.net_profit) - SUM(combined.net_loss)) AS net_contribution
FROM combined
GROUP BY combined.year, combined.promo_id
ORDER BY combined.year, total_net_profit DESC
