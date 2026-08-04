WITH date_filtered AS (
        SELECT d.d_date_sk, d.d_year, d.d_month_seq
        FROM date_dim d
        WHERE d.d_year = 2001
          AND d.d_month_seq BETWEEN 1200 AND 1210
    ),
    sales AS (
        SELECT ss.*, df.d_year, df.d_month_seq
        FROM store_sales ss
        JOIN date_filtered df ON ss.ss_sold_date_sk = df.d_date_sk
        WHERE ss.ss_quantity > 1
          AND ss.ss_sales_price > 10.0
          AND ss.ss_net_profit <> 0
    ),
    customer_filtered AS (
        SELECT c.c_customer_sk, c.c_birth_country
        FROM customer c
        WHERE c.c_birth_country IN ('MEXICO', 'SWITZERLAND')
    ),
    demo_filtered AS (
        SELECT cd.cd_demo_sk, cd.cd_gender
        FROM customer_demographics cd
        WHERE cd.cd_gender = 'F'
    ),
    hh_demo_filtered AS (
        SELECT hd.hd_demo_sk, hd.hd_income_band_sk
        FROM household_demographics hd
        WHERE hd.hd_income_band_sk IN (1, 2, 3)
    ),
    promo_filtered AS (
        SELECT p.p_promo_sk, p.p_promo_id, p.p_discount_active
        FROM promotion p
        WHERE p.p_discount_active = 'Y'
    ),
    store_filtered AS (
        SELECT s.s_store_sk, s.s_state, s.s_gmt_offset
        FROM store s
        WHERE s.s_gmt_offset = -6.00
          AND s.s_store_sk IN (
                SELECT s2.s_store_sk FROM store s2 WHERE s2.s_state = 'TX'
                EXCEPT
                SELECT s3.s_store_sk FROM store s3 WHERE s3.s_state = 'CA'
          )
    ),
    catalog_filtered AS (
        SELECT cp.cp_catalog_page_sk, cp.cp_type, cp.cp_start_date_sk
        FROM catalog_page cp
        WHERE cp.cp_type = 'PREMIUM'
    )
SELECT
    st.s_state,
    cp.cp_type,
    p.p_promo_id,
    COUNT(DISTINCT s.ss_ticket_number) AS uniq_ticket_cnt,
    SUM(s.ss_ext_sales_price) AS total_sales,
    AVG(s.ss_net_profit) AS avg_profit,
    MIN(s.ss_sold_date_sk) AS min_sold_date_sk,
    MAX(s.ss_sold_date_sk) AS max_sold_date_sk,
    (SELECT COUNT(*) FROM promotion WHERE p_discount_active = 'Y') AS active_promo_cnt
FROM sales s
JOIN customer_filtered c ON s.ss_customer_sk = c.c_customer_sk
JOIN demo_filtered d ON s.ss_cdemo_sk = d.cd_demo_sk
JOIN hh_demo_filtered h ON s.ss_hdemo_sk = h.hd_demo_sk
JOIN promo_filtered p ON s.ss_promo_sk = p.p_promo_sk
RIGHT OUTER JOIN store_filtered st ON s.ss_store_sk = st.s_store_sk
LEFT JOIN store_returns r ON r.sr_ticket_number = s.ss_ticket_number
                         AND r.sr_item_sk = s.ss_item_sk
                         AND r.sr_store_sk IN (SELECT s4.s_store_sk FROM store s4 WHERE s4.s_gmt_offset = -6.00)
JOIN catalog_filtered cp ON cp.cp_start_date_sk = s.ss_sold_date_sk
WHERE EXISTS (
        SELECT 1 FROM promotion p2 WHERE p2.p_promo_sk = s.ss_promo_sk AND p2.p_discount_active = 'Y'
    )
GROUP BY st.s_state, cp.cp_type, p.p_promo_id
ORDER BY total_sales DESC
LIMIT 100
