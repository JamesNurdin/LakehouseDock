WITH cs_joined AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_promo_sk,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        d1.d_year AS year,
        t.t_hour AS hour,
        i.i_category AS category,
        p.p_discount_active,
        c.c_birth_year,
        cd.cd_gender AS gender,
        hd.hd_buy_potential AS buy_potential,
        ib.ib_upper_bound
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN tpcds.time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
ss_joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        d2.d_year AS year,
        t.t_hour AS hour,
        i.i_category AS category,
        p.p_discount_active,
        c.c_birth_year,
        cd.cd_gender AS gender,
        hd.hd_buy_potential AS buy_potential,
        ib.ib_upper_bound,
        s.s_store_name
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
)
SELECT
    year,
    hour,
    category,
    gender,
    buy_potential,
    COUNT(*) AS sales_count,
    SUM(net_paid) AS total_net_paid,
    CASE
        WHEN SUM(net_paid) > (
            SELECT AVG(net_paid) FROM (
                SELECT cs.cs_net_paid AS net_paid FROM tpcds.catalog_sales cs
                UNION ALL
                SELECT ss.ss_net_paid AS net_paid FROM tpcds.store_sales ss
            ) sub_avg
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_category
FROM (
    SELECT
        year,
        hour,
        category,
        gender,
        buy_potential,
        cs_net_paid AS net_paid
    FROM cs_joined
    UNION
    SELECT
        year,
        hour,
        category,
        gender,
        buy_potential,
        ss_net_paid AS net_paid
    FROM ss_joined
) combined
WHERE category IN (
    SELECT i_category FROM tpcds.item WHERE i_brand = 'Brand#12'
    INTERSECT
    SELECT i_category FROM tpcds.item WHERE i_color = 'Red'
)
GROUP BY
    year,
    hour,
    category,
    gender,
    buy_potential
ORDER BY
    total_net_paid DESC
LIMIT 100
