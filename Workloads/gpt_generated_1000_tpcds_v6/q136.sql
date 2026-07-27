WITH store_agg AS (
    SELECT
        ss_promo_sk,
        ss_cdemo_sk,
        SUM(ss_net_profit) AS store_net_profit,
        SUM(ss_quantity) AS store_qty
    FROM store_sales
    WHERE ss_net_profit > 500
    GROUP BY ss_promo_sk, ss_cdemo_sk
)
SELECT
    p.p_promo_id,
    cd.cd_gender,
    cd.cd_education_status,
    SUM(cs.cs_net_paid_inc_ship) AS catalog_net_paid_inc_ship,
    SUM(ws.ws_net_paid) AS web_net_paid,
    store_agg.store_net_profit,
    (SUM(cs.cs_net_paid_inc_ship) + store_agg.store_net_profit + SUM(ws.ws_net_paid)) AS total_net,
    RANK() OVER (ORDER BY (SUM(cs.cs_net_paid_inc_ship) + store_agg.store_net_profit + SUM(ws.ws_net_paid)) DESC) AS net_profit_rank
FROM catalog_sales cs
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN store_agg
    ON store_agg.ss_promo_sk = p.p_promo_sk
   AND store_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   AND ws.ws_promo_sk = p.p_promo_sk
WHERE cs.cs_net_paid_inc_ship > 2000
  AND ws.ws_ext_discount_amt < 2000
  AND p.p_purpose = 'Unknown'
  AND cd.cd_gender = 'F'
  AND cs.cs_quantity >= 2
GROUP BY
    p.p_promo_id,
    cd.cd_gender,
    cd.cd_education_status,
    store_agg.store_net_profit
ORDER BY net_profit_rank
LIMIT 100
