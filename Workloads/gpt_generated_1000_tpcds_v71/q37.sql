WITH sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_ticket_number,
        ss.ss_item_sk
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND cd.cd_gender = 'M'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND hd.hd_vehicle_count >= 1
)
SELECT
    s.s_store_name,
    p.p_promo_name,
    d.d_year,
    cd.cd_gender,
    ib.ib_lower_bound,
    COUNT(DISTINCT sales.ss_ticket_number) AS num_tickets,
    SUM(sales.ss_net_paid) AS total_sales,
    SUM(sales.ss_ext_discount_amt) AS total_discount,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_returns,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_catalog_returns,
    AVG(sales.ss_net_paid) AS avg_ticket_value
FROM sales
JOIN tpcds.store s ON sales.ss_store_sk = s.s_store_sk
JOIN tpcds.promotion p ON sales.ss_promo_sk = p.p_promo_sk
JOIN tpcds.date_dim d ON sales.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.customer_demographics cd ON sales.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd ON sales.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = sales.ss_ticket_number
   AND sr.sr_store_sk = s.s_store_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
WHERE EXISTS (
        SELECT 1
        FROM tpcds.call_center cc
        WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
          AND cc.cc_country = 'United States'
    )
  AND cr.cr_ship_mode_sk IN (
        SELECT sm.sm_ship_mode_sk
        FROM tpcds.ship_mode sm
        WHERE sm.sm_carrier = 'DHL'
    )
  AND ib.ib_lower_bound >= 50000
GROUP BY
    s.s_store_name,
    p.p_promo_name,
    d.d_year,
    cd.cd_gender,
    ib.ib_lower_bound
ORDER BY total_sales DESC
LIMIT 100
