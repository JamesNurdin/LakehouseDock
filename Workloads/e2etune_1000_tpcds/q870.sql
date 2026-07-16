WITH cs_agg AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        cd.cd_demo_sk AS demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND p.p_discount_active = 'Y'
    GROUP BY cs.cs_promo_sk, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
sr_agg AS (
    SELECT
        sr.sr_cdemo_sk AS demo_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_cdemo_sk
)
SELECT
    p.p_promo_name,
    cs_agg.cd_gender,
    cs_agg.cd_marital_status,
    cs_agg.total_net_profit,
    cs_agg.total_sales_price,
    cs_agg.sales_cnt,
    COALESCE(sr_agg.total_net_loss, 0) AS total_return_loss,
    cs_agg.total_net_profit - COALESCE(sr_agg.total_net_loss, 0) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY cs_agg.cd_gender ORDER BY cs_agg.total_net_profit - COALESCE(sr_agg.total_net_loss, 0) DESC) AS gender_rank
FROM cs_agg
JOIN promotion p
    ON cs_agg.promo_sk = p.p_promo_sk
LEFT JOIN sr_agg
    ON cs_agg.demo_sk = sr_agg.demo_sk
WHERE cs_agg.total_net_profit > 0
ORDER BY net_profit_after_returns DESC
LIMIT 10
