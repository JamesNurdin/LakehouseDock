WITH active_promotions AS (
    SELECT
        p_promo_sk,
        p_promo_id,
        p_promo_name,
        p_start_date_sk,
        p_end_date_sk,
        p_cost,
        p_channel_radio,
        p_discount_active
    FROM promotion
    WHERE p_discount_active = 'Y'
      AND p_start_date_sk >= 2450200
),
customer_last_review AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_email_address,
        c_last_review_date,
        CASE
            WHEN lower(c_email_address) LIKE '%.edu' THEN 1
            ELSE 0
        END AS is_edu_email
    FROM customer
    WHERE c_last_review_date >= 2452000
),
promo_cust AS (
    SELECT
        ap.p_promo_id,
        ap.p_promo_name,
        ap.p_cost,
        COUNT(DISTINCT cl.c_customer_sk) AS cust_cnt,
        SUM(cl.is_edu_email) AS edu_cnt
    FROM active_promotions ap
    JOIN customer_last_review cl
        ON cl.c_last_review_date BETWEEN ap.p_start_date_sk AND ap.p_end_date_sk
    GROUP BY
        ap.p_promo_id,
        ap.p_promo_name,
        ap.p_cost
),
promo_ranked AS (
    SELECT
        pc.p_promo_id,
        pc.p_promo_name,
        pc.p_cost,
        pc.cust_cnt,
        pc.edu_cnt,
        CAST(pc.edu_cnt AS double) / pc.cust_cnt AS edu_email_ratio,
        ROW_NUMBER() OVER (ORDER BY pc.cust_cnt DESC) AS cust_cnt_rank,
        PERCENT_RANK() OVER (ORDER BY pc.cust_cnt) AS cust_cnt_pct_rank
    FROM promo_cust pc
)
SELECT
    pr.p_promo_id,
    pr.p_promo_name,
    pr.p_cost AS promo_cost,
    pr.cust_cnt,
    pr.edu_cnt,
    pr.edu_email_ratio,
    pr.cust_cnt_rank,
    pr.cust_cnt_pct_rank
FROM promo_ranked pr
ORDER BY pr.cust_cnt DESC
LIMIT 10
