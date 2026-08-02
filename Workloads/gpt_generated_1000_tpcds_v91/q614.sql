WITH promo_set_a AS (
    SELECT p.p_promo_sk
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '^[A-Z]{3}[0-9]{2}$')
      AND p.p_channel_email LIKE 'Y%'
),
promo_set_b AS (
    SELECT p.p_promo_sk
    FROM promotion p
    WHERE lower(p.p_purpose) LIKE '%clearance%'
      AND regexp_extract(p.p_promo_id, '[0-9]+', 0) IS NOT NULL
),
common_promos AS (
    SELECT p_promo_sk FROM promo_set_a
    INTERSECT
    SELECT p_promo_sk FROM promo_set_b
),
sales_agg AS (
    SELECT 
        ss.ss_promo_sk,
        sum(ss.ss_net_paid) AS total_net_paid,
        sum(ss.ss_quantity) AS total_quantity,
        count(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        avg(ss.ss_net_paid) AS avg_net_paid
    FROM store_sales ss
    JOIN common_promos cp ON ss.ss_promo_sk = cp.p_promo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_marital_status = 'M'
      AND hd.hd_buy_potential LIKE 'HIGH%'
      AND ib.ib_upper_bound > 50000
      AND td.t_meal_time LIKE 'Breakfast%'
    GROUP BY ss.ss_promo_sk
    HAVING sum(ss.ss_net_paid) > (SELECT avg(ss2.ss_net_paid) FROM store_sales ss2)
)
SELECT 
    cp.p_promo_sk,
    p.p_promo_name,
    p.p_discount_active,
    concat(p.p_promo_id, '-', p.p_promo_name) AS promo_label,
    substring(p.p_promo_name, 1, 5) AS promo_name_prefix,
    sa.total_net_paid,
    sa.total_quantity,
    sa.distinct_tickets,
    sa.avg_net_paid
FROM common_promos cp
JOIN promotion p ON cp.p_promo_sk = p.p_promo_sk
JOIN sales_agg sa ON cp.p_promo_sk = sa.ss_promo_sk
ORDER BY sa.total_net_paid DESC
LIMIT 100
