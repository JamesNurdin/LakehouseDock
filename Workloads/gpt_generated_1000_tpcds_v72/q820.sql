WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        p.p_promo_id,
        p.p_channel_email,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_sales_price,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
        AND c.c_birth_year BETWEEN 1950 AND 1980
        AND cd.cd_marital_status = 'M'
        AND hd.hd_vehicle_count >= 2
        AND ib.ib_upper_bound <= 50000
        AND p.p_channel_email = 'Y'
        AND wp.wp_type = 'product'
),
aggregated_data AS (
    SELECT
        jd.c_customer_id,
        jd.c_birth_year,
        jd.cd_gender,
        COUNT(DISTINCT jd.ss_ticket_number) AS distinct_tickets,
        SUM(jd.ss_quantity) AS total_quantity,
        SUM(jd.ss_net_paid) AS total_net_paid,
        AVG(jd.ss_sales_price) AS avg_sales_price,
        MIN(jd.ss_sales_price) AS min_sales_price,
        MAX(jd.ss_sales_price) AS max_sales_price
    FROM joined_data jd
    GROUP BY jd.c_customer_id, jd.c_birth_year, jd.cd_gender
)
SELECT
    ad.c_customer_id,
    ad.c_birth_year,
    ad.cd_gender,
    ad.distinct_tickets,
    ad.total_quantity,
    ad.total_net_paid,
    ad.avg_sales_price,
    ad.min_sales_price,
    ad.max_sales_price,
    (
        SELECT COUNT(DISTINCT p2.p_promo_id)
        FROM promotion p2
        WHERE p2.p_discount_active = 'Y'
          AND p2.p_channel_email = 'Y'
    ) AS active_email_promo_count,
    RANK() OVER (PARTITION BY ad.cd_gender ORDER BY ad.total_net_paid DESC) AS gender_net_paid_rank,
    SUM(ad.total_net_paid) OVER (
        PARTITION BY ad.c_birth_year
        ORDER BY ad.total_net_paid
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_paid_by_birth_year
FROM aggregated_data ad
ORDER BY ad.total_net_paid DESC
LIMIT 100
