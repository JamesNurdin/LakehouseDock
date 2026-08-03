WITH base_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_ship_cost,
        cr.cr_order_number,
        d.d_year,
        t.t_hour,
        i.i_brand,
        cc.cc_state,
        ca.ca_state AS ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        p.p_promo_name,
        p.p_discount_active,
        hd.hd_vehicle_count
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'Brand#12'
      AND cc.cc_state = 'CA'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_lower_bound >= 50000
      AND p.p_discount_active = 'Y'
)
SELECT
    d_year,
    i_brand,
    cc_state,
    hd_income_band_sk,
    p_promo_name,
    COUNT(DISTINCT cr_order_number) AS orders_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_tax) AS avg_return_tax,
    MIN(cr_return_ship_cost) AS min_ship_cost,
    MAX(cr_return_ship_cost) AS max_ship_cost
FROM base_data
GROUP BY CUBE (d_year, i_brand, cc_state, hd_income_band_sk, p_promo_name)
ORDER BY total_return_amount DESC
LIMIT 100
