WITH cs_agg AS (
    SELECT
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_promo_sk,
        cs_bill_hdemo_sk,
        cs_ship_hdemo_sk,
        cs_bill_addr_sk,
        cs_ship_addr_sk,
        SUM(cs_quantity)          AS total_quantity,
        SUM(cs_net_paid)          AS total_net_paid,
        COUNT(*)                  AS order_cnt
    FROM tpcds.catalog_sales
    WHERE cs_sold_time_sk IN (60802, 55545)
    GROUP BY
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_promo_sk,
        cs_bill_hdemo_sk,
        cs_ship_hdemo_sk,
        cs_bill_addr_sk,
        cs_ship_addr_sk
)
SELECT
    cp.cp_catalog_page_id,
    sm.sm_type,
    sm.sm_carrier,
    p.p_promo_name,
    p.p_response_target,
    hd_bill.hd_buy_potential,
    ib_bill.ib_lower_bound,
    hd_ship.hd_vehicle_count,
    ib_ship.ib_upper_bound,
    cs_agg.total_quantity,
    cs_agg.total_net_paid,
    cs_agg.order_cnt,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    (
        SELECT AVG(ib_lower_bound)
        FROM tpcds.income_band
    ) AS avg_income_lower_bound
FROM cs_agg
JOIN tpcds.catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN tpcds.household_demographics hd_bill
    ON cs_agg.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship
    ON cs_agg.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.income_band ib_bill
    ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN tpcds.income_band ib_ship
    ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
JOIN tpcds.customer_address ca_bill
    ON cs_agg.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
    ON cs_agg.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE p.p_channel_event = 'N'
  AND sm.sm_type = 'EXPRESS'
  AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_promo_sk = cs_agg.cs_promo_sk
          AND cs2.cs_quantity > 5
      )
ORDER BY cs_agg.total_net_paid DESC
LIMIT 100
