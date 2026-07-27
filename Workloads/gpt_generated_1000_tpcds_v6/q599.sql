WITH sales_filtered AS (
    SELECT
        ss.ss_item_sk,
        i.i_brand,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE i.i_brand = 'brandnameless #5'
      AND i.i_wholesale_cost > 5.00
      AND c.c_birth_year = 1984
      AND hd.hd_income_band_sk = 10
      AND p.p_discount_active = 'Y'
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
)
SELECT
    sf.i_brand,
    sf.cd_gender,
    sf.hd_income_band_sk,
    COUNT(*) AS sales_cnt,
    SUM(sf.ss_quantity) AS total_quantity,
    SUM(sf.ss_net_paid) AS total_net_paid,
    AVG(sf.ss_net_paid) AS avg_net_paid,
    MAX(sf.ss_net_profit) AS max_profit,
    (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = sf.ss_item_sk
    ) AS item_avg_net_paid
FROM sales_filtered sf
GROUP BY sf.i_brand, sf.cd_gender, sf.hd_income_band_sk, sf.ss_item_sk
ORDER BY total_net_paid DESC
LIMIT 100
