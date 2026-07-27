WITH filtered AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        cc.cc_state,
        p.p_discount_active,
        cs.cs_net_paid,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cs.cs_quantity,
        ss.ss_quantity,
        ws.ws_quantity
    FROM tpcds.customer_demographics cd
    JOIN tpcds.store_sales ss
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.promotion p
        ON p.p_promo_sk = cs.cs_promo_sk
    JOIN tpcds.call_center cc
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
    WHERE cd.cd_credit_rating = 'High Risk'
      AND cd.cd_dep_count <= 2
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 5
)
SELECT
    cd_credit_rating,
    cd_purchase_estimate,
    cc_state,
    CASE WHEN cd_credit_rating = 'High Risk' THEN 'Risky' ELSE 'Other' END AS risk_category,
    COUNT(DISTINCT cd_demo_sk) AS demo_count,
    SUM(cs_net_paid + ss_net_paid + ws_net_paid) AS total_net_paid,
    AVG(cs_quantity + ss_quantity + ws_quantity) AS avg_quantity,
    MIN(cs_net_paid) AS min_catalog_net,
    MAX(ws_net_paid) AS max_web_net
FROM filtered
GROUP BY
    cd_credit_rating,
    cd_purchase_estimate,
    cc_state,
    CASE WHEN cd_credit_rating = 'High Risk' THEN 'Risky' ELSE 'Other' END
ORDER BY total_net_paid DESC
LIMIT 100
