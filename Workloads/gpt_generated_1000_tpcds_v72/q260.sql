WITH catalog_agg AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        cs_sold_date_sk AS sold_date_sk,
        cs_ship_mode_sk AS ship_mode_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity
    FROM tpcds.catalog_sales
    WHERE cs_net_paid > 0
    GROUP BY cs_bill_customer_sk, cs_sold_date_sk, cs_ship_mode_sk
)
SELECT
    c.c_customer_id,
    d.d_date,
    p.p_promo_name,
    sm.sm_type,
    ss.ss_ext_tax,
    hd.hd_buy_potential,
    ca.total_net_paid,
    ca.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ca.total_net_paid DESC) AS rn_customer,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ss.ss_ext_tax DESC) AS tax_rank_year
FROM catalog_agg ca
JOIN tpcds.customer c
    ON ca.customer_sk = c.c_customer_sk
JOIN tpcds.date_dim d
    ON ca.sold_date_sk = d.d_date_sk
JOIN tpcds.store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
    AND ss.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm
    ON ca.ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN tpcds.household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
ORDER BY ca.total_net_paid DESC
LIMIT 100
