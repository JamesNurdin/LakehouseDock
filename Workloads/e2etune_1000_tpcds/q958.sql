WITH store_agg AS (
    SELECT
        ss.ss_promo_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customer_cnt,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
      AND p.p_discount_active = 'Y'
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY ss.ss_promo_sk
),
return_agg AS (
    SELECT
        ss.ss_promo_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
      AND p.p_discount_active = 'Y'
      AND sr.sr_returned_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY ss.ss_promo_sk
),
web_agg AS (
    SELECT
        ws.ws_promo_sk,
        ws_site.web_state,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customer_cnt,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE p.p_channel_tv = 'Y'
      AND p.p_discount_active = 'Y'
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY ws.ws_promo_sk, ws_site.web_state
)
SELECT
    p.p_promo_name,
    wa.web_state,
    COALESCE(sa.store_net_profit, 0) AS store_net_profit,
    COALESCE(wa.web_net_profit, 0) AS web_net_profit,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    (COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    COALESCE(sa.store_customer_cnt, 0) + COALESCE(wa.web_customer_cnt, 0) AS total_customers,
    RANK() OVER (ORDER BY (COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) - COALESCE(ra.total_return_loss, 0)) DESC) AS profit_rank
FROM promotion p
LEFT JOIN store_agg sa ON p.p_promo_sk = sa.ss_promo_sk
LEFT JOIN return_agg ra ON p.p_promo_sk = ra.ss_promo_sk
LEFT JOIN web_agg wa ON p.p_promo_sk = wa.ws_promo_sk
WHERE p.p_channel_tv = 'Y'
  AND p.p_discount_active = 'Y'
  AND p.p_start_date_sk <= 2451088
  AND p.p_end_date_sk >= 2450815
ORDER BY net_profit_after_returns DESC
LIMIT 10
