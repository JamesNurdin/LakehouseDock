WITH sales_agg AS (
    SELECT
        cs.cs_promo_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number,
        c.c_birth_country
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
)
SELECT
    p.p_promo_name,
    td.t_hour,
    cd.cd_gender,
    COUNT(DISTINCT sa.cs_order_number) AS order_cnt,
    SUM(sa.cs_quantity) AS total_quantity,
    SUM(sa.cs_net_paid) AS total_net_paid,
    AVG(sa.cs_net_profit) AS avg_net_profit,
    SUM(sa.cs_net_profit) / NULLIF(SUM(sa.cs_net_paid), 0) AS profit_margin
FROM sales_agg sa
JOIN promotion p
    ON sa.cs_promo_sk = p.p_promo_sk
JOIN time_dim td
    ON sa.cs_sold_time_sk = td.t_time_sk
JOIN customer_demographics cd
    ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE p.p_discount_active = 'Y'
  AND p.p_channel_email = 'Y'
  AND td.t_hour BETWEEN 9 AND 18
  AND sa.c_birth_country = 'United States'
GROUP BY p.p_promo_name, td.t_hour, cd.cd_gender
ORDER BY total_net_paid DESC
LIMIT 50
