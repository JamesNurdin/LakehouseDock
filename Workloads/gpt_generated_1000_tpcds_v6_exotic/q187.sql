WITH sales_joined AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
)
SELECT
    d.d_year,
    cc.cc_name,
    COUNT(DISTINCT sj.cs_order_number) AS order_cnt,
    SUM(sj.cs_net_paid) AS total_net_paid,
    AVG(sj.cs_net_profit) AS avg_net_profit,
    CASE
        WHEN SUM(sj.cs_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status
FROM sales_joined sj
JOIN date_dim d
    ON sj.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON sj.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN promotion p
    ON sj.cs_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND cc.cc_state = 'CA'
  AND sj.cs_net_paid >= 1000
  AND (p.p_discount_active = 'Y' OR p.p_promo_sk IS NULL)
GROUP BY d.d_year, cc.cc_name
ORDER BY total_net_paid DESC
LIMIT 100
