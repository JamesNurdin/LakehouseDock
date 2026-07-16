WITH promo_sales AS (
    SELECT
        p.p_promo_name AS promo_name,
        p.p_discount_active AS discount_active,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2458849 AND 2458949
      AND cd.cd_purchase_estimate >= 1500
      AND cd.cd_credit_rating = 'Good'
      AND p.p_discount_active = 'Y'
      AND hd.hd_income_band_sk IS NOT NULL
    GROUP BY p.p_promo_name, p.p_discount_active, cd.cd_gender, cd.cd_marital_status
)
SELECT
    promo_name,
    gender,
    marital_status,
    total_net_paid,
    total_net_profit,
    avg_discount,
    sales_cnt,
    RANK() OVER (PARTITION BY gender ORDER BY total_net_profit DESC) AS gender_rank
FROM promo_sales
WHERE total_net_paid > 10000
ORDER BY total_net_profit DESC
LIMIT 20
