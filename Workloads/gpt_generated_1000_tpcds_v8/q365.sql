WITH
sales_agg AS (
    SELECT
        ss_store_sk,
        ss_promo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS trans_cnt
    FROM store_sales
    WHERE ss_ext_sales_price > 100
      AND ss_ext_tax < 30
      AND ss_quantity > 0
      AND ss_net_paid > 0
      AND ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ss_store_sk, ss_promo_sk
),
common_store_sk AS (
    SELECT ss_store_sk
    FROM sales_agg
    INTERSECT
    SELECT s_store_sk
    FROM store
    WHERE s_tax_percentage BETWEEN 0.03 AND 0.10
      AND s_state = 'CA'
      AND s_city IN ('Los Angeles', 'San Diego')
      AND s_rec_end_date > DATE '2000-01-01'
),
promo_filtered AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_channel_dmail = 'Y'
      AND p_channel_email = 'Y'
      AND p_channel_catalog = 'N'
      AND p_response_target > 0
      AND p_discount_active = 'Y'
),
filtered_sales AS (
    SELECT
        sa.ss_store_sk,
        s.s_state,
        s.s_city,
        s.s_tax_percentage,
        p.p_promo_name,
        hd.hd_buy_potential,
        sa.total_sales,
        sa.avg_discount,
        sa.trans_cnt,
        CASE WHEN s.s_tax_percentage > 0.08 THEN 'HighTax' ELSE 'LowTax' END AS tax_category
    FROM sales_agg sa
    JOIN common_store_sk cs ON cs.ss_store_sk = sa.ss_store_sk
    JOIN store s ON s.s_store_sk = sa.ss_store_sk
    JOIN promotion p ON p.p_promo_sk = sa.ss_promo_sk
    JOIN promo_filtered pf ON pf.p_promo_sk = p.p_promo_sk
    JOIN (
        SELECT ss_store_sk, ss_hdemo_sk
        FROM store_sales
        WHERE ss_ext_sales_price > 100
    ) sh ON sh.ss_store_sk = sa.ss_store_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = sh.ss_hdemo_sk
    WHERE s.s_floor_space > 2000
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_dep_count <= 5
      AND hd.hd_buy_potential IS NOT NULL
),
grouped AS (
    SELECT
        s_state,
        s_city,
        p_promo_name,
        hd_buy_potential,
        tax_category,
        SUM(total_sales) AS sum_sales,
        AVG(avg_discount) AS avg_discount_overall,
        SUM(trans_cnt) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY SUM(total_sales) DESC) AS rn_state
    FROM filtered_sales
    GROUP BY GROUPING SETS (
        (s_state, s_city, p_promo_name, hd_buy_potential, tax_category),
        (s_state, s_city, tax_category),
        (s_state, tax_category),
        (tax_category)
    )
)
SELECT
    g.s_state,
    g.s_city,
    g.p_promo_name,
    g.hd_buy_potential,
    g.tax_category,
    g.sum_sales,
    g.avg_discount_overall,
    g.total_transactions,
    g.rn_state,
    u.state_or_city
FROM grouped g
LEFT JOIN UNNEST(ARRAY[g.s_state, g.s_city]) AS u(state_or_city) ON TRUE
ORDER BY g.s_state, g.sum_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
