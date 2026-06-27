WITH catalog_agg AS (
    SELECT
        p.p_promo_name,
        date_trunc('month', d.d_date) AS month_start,
        SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_name, date_trunc('month', d.d_date)
),
web_agg AS (
    SELECT
        p.p_promo_name,
        date_trunc('month', d.d_date) AS month_start,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_name, date_trunc('month', d.d_date)
),
returns_agg AS (
    SELECT
        p.p_promo_name,
        date_trunc('month', d.d_date) AS month_start,
        SUM(wr.wr_net_loss) AS returns_net_loss
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_name, date_trunc('month', d.d_date)
)
SELECT
    COALESCE(c.p_promo_name, w.p_promo_name, r.p_promo_name) AS promo_name,
    COALESCE(c.month_start, w.month_start, r.month_start) AS month_start,
    c.catalog_net_profit,
    w.web_net_profit,
    r.returns_net_loss,
    (COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) - COALESCE(r.returns_net_loss, 0)) AS total_net
FROM catalog_agg c
FULL OUTER JOIN web_agg w
    ON c.p_promo_name = w.p_promo_name
   AND c.month_start = w.month_start
FULL OUTER JOIN returns_agg r
    ON COALESCE(c.p_promo_name, w.p_promo_name) = r.p_promo_name
   AND COALESCE(c.month_start, w.month_start) = r.month_start
ORDER BY promo_name, month_start
