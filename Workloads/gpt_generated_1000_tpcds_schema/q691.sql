WITH ws_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        MIN(ws.ws_sold_date_sk) AS first_sale_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_wholesale_cost > 10
      AND ws.ws_net_paid_inc_ship > 500
      AND sm.sm_carrier = 'UPS'
      AND wp.wp_type = 'product'
      AND c.c_salutation = 'Mr.'
      AND cd.cd_gender = 'M'
    GROUP BY GROUPING SETS (
        (ws.ws_bill_customer_sk),
        ()
    )
),
wr_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wr.wr_fee > 20
      AND wr.wr_reversed_charge < 200
    GROUP BY wr.wr_refunded_customer_sk
),
sr_agg AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_net_loss) AS total_store_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_quantity > 10
      AND sr.sr_return_ship_cost < 100
    GROUP BY sr.sr_customer_sk
),
combined AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wa.total_profit,
        wa.total_sales,
        wa.sales_cnt,
        wr.total_return_loss,
        wr.return_cnt,
        sr.total_store_loss,
        sr.store_return_cnt,
        (wa.total_profit - COALESCE(wr.total_return_loss, 0) - COALESCE(sr.total_store_loss, 0)) AS net_contribution
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN ws_agg wa ON c.c_customer_sk = wa.customer_sk
    LEFT JOIN wr_agg wr ON c.c_customer_sk = wr.customer_sk
    LEFT JOIN sr_agg sr ON c.c_customer_sk = sr.customer_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1980
      AND ib.ib_upper_bound IS NOT NULL
),
eligible_customers AS (
    SELECT c.c_customer_sk
    FROM combined c
    WHERE c.net_contribution > 0
    EXCEPT
    SELECT sr.sr_customer_sk
    FROM store_returns sr
    WHERE sr.sr_net_loss > 0
)
SELECT
    ec.c_customer_sk,
    cmb.c_first_name,
    cmb.c_last_name,
    cmb.cd_education_status,
    cmb.hd_income_band_sk,
    cmb.ib_lower_bound,
    cmb.ib_upper_bound,
    cmb.net_contribution,
    pv.page_visits,
    RANK() OVER (ORDER BY cmb.net_contribution DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY cmb.hd_income_band_sk ORDER BY cmb.net_contribution DESC) AS income_band_row
FROM eligible_customers ec
JOIN combined cmb ON ec.c_customer_sk = cmb.c_customer_sk
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS page_visits
    FROM web_page wp
    WHERE wp.wp_customer_sk = cmb.c_customer_sk
) AS pv
CROSS JOIN (
    SELECT level FROM (VALUES 1, 2, 3) AS t(level)
) AS levels
WHERE EXISTS (
    SELECT 1
    FROM ship_mode sm
    WHERE sm.sm_carrier = 'UPS' AND sm.sm_type = 'Air'
)
ORDER BY profit_rank
LIMIT 100
