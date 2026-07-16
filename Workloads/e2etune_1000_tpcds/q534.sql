WITH store_sales_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_net_paid) AS store_net_paid,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND p.p_cost > 1000
    GROUP BY p.p_promo_sk, p.p_promo_name
),
web_sales_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_net_paid) AS web_net_paid,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND p.p_cost > 1000
    GROUP BY p.p_promo_sk, p.p_promo_name
),
store_returns_agg AS (
    SELECT
        p.p_promo_sk,
        SUM(sr.sr_net_loss) AS store_return_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_item_sk = ss.ss_item_sk
                         AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND p.p_cost > 1000
    GROUP BY p.p_promo_sk
),
web_returns_agg AS (
    SELECT
        p.p_promo_sk,
        SUM(wr.wr_net_loss) AS web_return_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
                       AND wr.wr_order_number = ws.ws_order_number
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND p.p_cost > 1000
    GROUP BY p.p_promo_sk
)
SELECT
    COALESCE(ss.p_promo_sk, ws.p_promo_sk) AS promo_sk,
    COALESCE(ss.p_promo_name, ws.p_promo_name) AS promo_name,
    ss.store_net_profit,
    ws.web_net_profit,
    (COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0)) AS total_net_profit,
    sr.store_return_loss,
    wr.web_return_loss,
    (COALESCE(sr.store_return_loss, 0) + COALESCE(wr.web_return_loss, 0)) AS total_return_loss,
    (COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
     - COALESCE(sr.store_return_loss, 0) - COALESCE(wr.web_return_loss, 0)) AS net_effect,
    (COALESCE(ss.store_sales_cnt, 0) + COALESCE(ws.web_sales_cnt, 0)) AS total_sales_cnt,
    (COALESCE(sr.store_return_cnt, 0) + COALESCE(wr.web_return_cnt, 0)) AS total_return_cnt,
    CASE
        WHEN (COALESCE(ss.store_sales_cnt, 0) + COALESCE(ws.web_sales_cnt, 0)) > 0
        THEN (COALESCE(sr.store_return_cnt, 0) + COALESCE(wr.web_return_cnt, 0)) * 1.0
             / (COALESCE(ss.store_sales_cnt, 0) + COALESCE(ws.web_sales_cnt, 0))
        ELSE NULL
    END AS return_rate
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.p_promo_sk = ws.p_promo_sk
FULL OUTER JOIN store_returns_agg sr ON COALESCE(ss.p_promo_sk, ws.p_promo_sk) = sr.p_promo_sk
FULL OUTER JOIN web_returns_agg wr ON COALESCE(ss.p_promo_sk, ws.p_promo_sk) = wr.p_promo_sk
WHERE (COALESCE(ss.store_net_paid, 0) + COALESCE(ws.web_net_paid, 0)) > 50000
ORDER BY net_effect DESC
LIMIT 100
