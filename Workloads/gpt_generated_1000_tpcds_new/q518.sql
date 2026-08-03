WITH sales_data AS (
    SELECT
        cs.cs_order_number AS order_id,
        cs.cs_net_paid_inc_ship_tax AS amount,
        c.c_customer_id AS customer_id,
        cd.cd_gender AS demo_attr,
        hd.hd_buy_potential AS buy_potential,
        p.p_promo_name AS source_name,
        cp.cp_department AS department,
        sm.sm_type AS ship_type,
        cc.cc_name AS call_center_name,
        chr AS name_char
    FROM catalog_sales cs
    RIGHT OUTER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band inc
        ON hd.hd_income_band_sk = inc.ib_income_band_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    CROSS JOIN UNNEST(split(c.c_first_name, '')) AS t(chr)
    WHERE cs.cs_net_paid_inc_ship_tax > 1000
      AND cd.cd_gender = 'M'
      AND inc.ib_upper_bound >= 50000
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr
          WHERE sr.sr_customer_sk = c.c_customer_sk
            AND sr.sr_return_amt > 0
      )
),
returns_data AS (
    SELECT
        sr.sr_ticket_number AS order_id,
        sr.sr_return_amt AS amount,
        c.c_customer_id AS customer_id,
        cd.cd_marital_status AS demo_attr,
        hd.hd_buy_potential AS buy_potential,
        s.s_store_name AS source_name,
        NULL AS department,
        NULL AS ship_type,
        NULL AS call_center_name,
        NULL AS name_char
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band inc
        ON hd.hd_income_band_sk = inc.ib_income_band_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_amt > 0
      AND s.s_state = 'CA'
      AND inc.ib_upper_bound < 100000
)
SELECT
    order_id,
    amount,
    customer_id,
    demo_attr,
    buy_potential,
    source_name,
    department,
    ship_type,
    call_center_name,
    name_char,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY amount DESC) AS rn
FROM (
    SELECT * FROM sales_data
    UNION DISTINCT
    SELECT * FROM returns_data
) AS combined
ORDER BY amount DESC
LIMIT 100
