WITH sales AS (
    SELECT
        cd.cd_demo_sk,
        p.p_promo_id,
        cp.cp_type,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
      AND cp.cp_type = 'monthly'
    GROUP BY cd.cd_demo_sk, p.p_promo_id, cp.cp_type
),
returns AS (
    SELECT
        cd.cd_demo_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY cd.cd_demo_sk
)
SELECT
    s.p_promo_id,
    s.cp_type,
    cd.cd_gender,
    cd.cd_marital_status,
    s.sales_cnt,
    s.total_net_paid_inc_tax,
    s.total_discount,
    s.total_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    COALESCE(r.returns_cnt, 0) AS returns_cnt,
    (s.total_profit - COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns,
    ROUND(s.total_discount / NULLIF(s.total_net_paid_inc_tax, 0) * 100, 2) AS discount_pct
FROM sales s
LEFT JOIN returns r ON s.cd_demo_sk = r.cd_demo_sk
JOIN customer_demographics cd ON s.cd_demo_sk = cd.cd_demo_sk
ORDER BY net_profit_after_returns DESC
LIMIT 20
