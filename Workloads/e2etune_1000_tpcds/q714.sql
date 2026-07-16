WITH cs_agg AS (
    SELECT
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        SUM(cs.cs_net_paid) AS cat_net_paid
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY cs.cs_promo_sk, cs.cs_call_center_sk
),
ss_agg AS (
    SELECT
        ss.ss_promo_sk,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY ss.ss_promo_sk
),
sr_agg AS (
    SELECT
        ss.ss_promo_sk AS sr_promo_sk,
        SUM(sr.sr_net_loss) AS returns_net_loss
    FROM store_sales ss
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2451000
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY ss.ss_promo_sk
)
SELECT
    cc.cc_mkt_class,
    p.p_promo_name,
    p.p_channel_email,
    COALESCE(cs_agg.cat_net_paid, 0) AS catalog_net_paid,
    COALESCE(ss_agg.store_net_profit, 0) AS store_net_profit,
    COALESCE(sr_agg.returns_net_loss, 0) AS returns_net_loss,
    (COALESCE(cs_agg.cat_net_paid, 0) + COALESCE(ss_agg.store_net_profit, 0) - COALESCE(sr_agg.returns_net_loss, 0)) AS net_revenue,
    RANK() OVER (PARTITION BY cc.cc_mkt_class ORDER BY (COALESCE(cs_agg.cat_net_paid, 0) + COALESCE(ss_agg.store_net_profit, 0) - COALESCE(sr_agg.returns_net_loss, 0)) DESC) AS revenue_rank
FROM cs_agg
JOIN promotion p ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ss_agg ON ss_agg.ss_promo_sk = cs_agg.cs_promo_sk
LEFT JOIN sr_agg ON sr_agg.sr_promo_sk = cs_agg.cs_promo_sk
WHERE cc.cc_employees > 2000000
  AND p.p_channel_email = 'Y'
  AND (COALESCE(cs_agg.cat_net_paid, 0) + COALESCE(ss_agg.store_net_profit, 0) - COALESCE(sr_agg.returns_net_loss, 0)) > 5000000
ORDER BY net_revenue DESC
LIMIT 100
