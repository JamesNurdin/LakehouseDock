WITH joined_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_quantity,
        cs.cs_order_number,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        p.p_channel_tv,
        p.p_channel_radio,
        p.p_channel_press,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        cc.cc_name,
        cc.cc_state,
        sm.sm_type
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_channel_tv = 'N'
      AND p.p_channel_radio = 'N'
      AND hd.hd_buy_potential = '501-1000'
),
promo_set AS (
    SELECT promo_sk FROM (
        SELECT DISTINCT cs.cs_promo_sk AS promo_sk
        FROM tpcds.catalog_sales cs
        WHERE cs.cs_net_paid_inc_ship_tax > 5000
        UNION
        SELECT DISTINCT cs.cs_promo_sk
        FROM tpcds.catalog_sales cs
        WHERE cs.cs_quantity > 5
    )
)
SELECT
    jd.bill_state,
    jd.ship_state,
    SUM(jd.cs_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(jd.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT jd.cs_order_number) AS distinct_orders
FROM joined_data jd
WHERE jd.cs_promo_sk IN (SELECT promo_sk FROM promo_set)
  AND jd.cs_ship_date_sk BETWEEN 2450834 AND 2450905
  AND jd.cc_state = 'CA'
GROUP BY GROUPING SETS (
    (jd.bill_state, jd.ship_state),
    (jd.bill_state),
    (jd.ship_state),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
