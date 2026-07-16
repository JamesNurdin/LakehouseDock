WITH cs_agg AS (
    SELECT cs.cs_promo_sk AS promo_sk,
           SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    WHERE d_cs.d_year = 2001
    GROUP BY cs.cs_promo_sk
),
ss_agg AS (
    SELECT ss.ss_promo_sk AS promo_sk,
           SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    WHERE d_ss.d_year = 2001
    GROUP BY ss.ss_promo_sk
),
ws_agg AS (
    SELECT ws.ws_promo_sk AS promo_sk,
           SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year = 2001
    GROUP BY ws.ws_promo_sk
),
wr_agg AS (
    SELECT ws.ws_promo_sk AS promo_sk,
           SUM(wr.wr_net_loss) AS return_net_loss
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                      AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE d_wr.d_year = 2001
    GROUP BY ws.ws_promo_sk
)
SELECT p.p_promo_id,
       p.p_promo_name,
       COALESCE(cs.catalog_net_profit, 0) AS catalog_net_profit,
       COALESCE(ss.store_net_profit, 0) AS store_net_profit,
       COALESCE(ws.web_net_profit, 0) AS web_net_profit,
       COALESCE(wr.return_net_loss, 0) AS total_return_net_loss,
       COALESCE(cs.catalog_net_profit, 0) + COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(wr.return_net_loss, 0) AS net_profit_after_returns
FROM promotion p
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
LEFT JOIN cs_agg cs ON p.p_promo_sk = cs.promo_sk
LEFT JOIN ss_agg ss ON p.p_promo_sk = ss.promo_sk
LEFT JOIN ws_agg ws ON p.p_promo_sk = ws.promo_sk
LEFT JOIN wr_agg wr ON p.p_promo_sk = wr.promo_sk
WHERE d_start.d_year <= 2001
  AND d_end.d_year   >= 2001
ORDER BY net_profit_after_returns DESC
LIMIT 20
