WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ship_mode_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cc.cc_name,
        cc.cc_state,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        cs.cs_ship_date_sk
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND ca.ca_state = 'TX'
      AND c.c_birth_year BETWEEN 1960 AND 1970
      AND cs.cs_quantity > 5
      AND cc.cc_rec_start_date >= DATE '2001-01-01'
)
SELECT
    sb.cc_name,
    CASE
        WHEN sb.cs_quantity > 10 THEN 'Large'
        ELSE 'Small'
    END AS quantity_category,
    sm.sm_carrier,
    COUNT(DISTINCT sb.cs_order_number) AS order_cnt,
    SUM(sb.cs_net_paid) AS total_net_paid,
    AVG(sb.cs_net_profit) AS avg_net_profit,
    SUM(CASE WHEN sb.cs_quantity > 10 THEN sb.cs_net_paid ELSE 0 END) AS high_qty_net_paid,
    MIN(sb.cs_ship_date_sk) AS earliest_ship_date_sk
FROM sales_base sb
JOIN ship_mode sm
    ON sb.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE EXISTS (
    SELECT 1
    FROM ship_mode sm2
    WHERE sm2.sm_ship_mode_sk = sb.cs_ship_mode_sk
      AND sm2.sm_carrier = 'DHL'
)
GROUP BY
    sb.cc_name,
    CASE
        WHEN sb.cs_quantity > 10 THEN 'Large'
        ELSE 'Small'
    END,
    sm.sm_carrier
ORDER BY total_net_paid DESC
LIMIT 100
