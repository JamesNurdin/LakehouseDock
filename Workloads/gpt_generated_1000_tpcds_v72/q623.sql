WITH catalog_part AS (
    SELECT
        ca.ca_state AS state,
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        sm.sm_type AS ship_type,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(*) AS return_cnt,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(cr.cr_net_loss) DESC) AS state_rank
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ca.ca_state = 'CA'
      AND i.i_category = 'Electronics'
      AND ib.ib_lower_bound >= 30000
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '5001-10000'
      AND cr.cr_return_amount > 100
      AND cr.cr_return_quantity > 1
    GROUP BY ca.ca_state, i.i_category, p.p_promo_name, sm.sm_type
    HAVING SUM(cr.cr_net_loss) > 0
),
web_part AS (
    SELECT
        ca.ca_state AS state,
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        CAST(NULL AS VARCHAR) AS ship_type,
        SUM(wr.wr_net_loss) AS total_return_loss,
        0 AS total_sales,
        COUNT(*) AS return_cnt,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(wr.wr_net_loss) DESC) AS state_rank
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE ca.ca_state IN ('CA', 'TX')
      AND i.i_category = 'Books'
      AND ib.ib_upper_bound < 80000
      AND cd.cd_gender = 'F'
      AND hd.hd_vehicle_count >= 2
      AND wr.wr_return_quantity > 0
    GROUP BY ca.ca_state, i.i_category, p.p_promo_name
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
    state,
    category,
    promo_name,
    ship_type,
    total_return_loss,
    total_sales,
    return_cnt,
    state_rank
FROM (
    SELECT * FROM catalog_part
    UNION ALL
    SELECT * FROM web_part
) AS combined
ORDER BY state, total_return_loss DESC
LIMIT 100
