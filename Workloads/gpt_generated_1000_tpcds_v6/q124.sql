WITH promo_sales AS (
    SELECT
        ss.ss_promo_sk,
        SUM(ss.ss_ext_sales_price) AS promo_sales_total,
        COUNT(*) AS promo_txn_cnt
    FROM store_sales ss
    WHERE ss.ss_sales_price > 20
      AND ss.ss_ext_discount_amt > 5
    GROUP BY ss.ss_promo_sk
)
SELECT
    cd.cd_gender,
    cd.cd_education_status,
    p.p_channel_email,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets,
    promo_sales.promo_sales_total,
    promo_sales.promo_txn_cnt,
    (SELECT AVG(ss2.ss_ext_sales_price) FROM store_sales ss2) AS overall_avg_sales
FROM store_sales ss
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN promo_sales
    ON ss.ss_promo_sk = promo_sales.ss_promo_sk
WHERE cd.cd_gender = 'M'
  AND cd.cd_marital_status = 'S'
  AND cd.cd_dep_count <= 2
  AND p.p_discount_active = 'Y'
  AND p.p_response_target >= 1
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
  AND p.p_channel_email = 'Y'
GROUP BY
    cd.cd_gender,
    cd.cd_education_status,
    p.p_channel_email,
    promo_sales.promo_sales_total,
    promo_sales.promo_txn_cnt
ORDER BY total_sales DESC
LIMIT 100
