WITH catalog_agg AS (
    SELECT 
        p.p_promo_id,
        sm.sm_type,
        cd.cd_gender,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2459000
      AND cs.cs_sales_price > 50
    GROUP BY p.p_promo_id, sm.sm_type, cd.cd_gender
),
web_agg AS (
    SELECT 
        p.p_promo_id,
        sm.sm_type,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS web_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_web_discount
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2459000
      AND ws.ws_sales_price > 50
    GROUP BY p.p_promo_id, sm.sm_type, cd.cd_gender
)
SELECT 
    COALESCE(ca.p_promo_id, wa.p_promo_id) AS promo_id,
    COALESCE(ca.sm_type, wa.sm_type) AS ship_mode,
    COALESCE(ca.cd_gender, wa.cd_gender) AS gender,
    COALESCE(ca.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(wa.web_net_profit, 0) AS web_net_profit,
    (COALESCE(ca.catalog_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) AS total_net_profit,
    COALESCE(ca.avg_catalog_discount, 0) AS avg_catalog_discount,
    COALESCE(wa.avg_web_discount, 0) AS avg_web_discount,
    RANK() OVER (ORDER BY (COALESCE(ca.catalog_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) DESC) AS profit_rank
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
  ON ca.p_promo_id = wa.p_promo_id
 AND ca.sm_type = wa.sm_type
 AND ca.cd_gender = wa.cd_gender
WHERE (COALESCE(ca.catalog_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
