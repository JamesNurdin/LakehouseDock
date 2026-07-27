WITH
return_data AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        'RETURN' AS trans_type,
        SUM(cr.cr_return_amount) AS total_amount,
        SUM(cr.cr_net_loss) AS net_metric,
        CASE WHEN sm.sm_type = 'OVERNIGHT' THEN 'Fast' ELSE 'Standard' END AS category,
        (SELECT AVG(p.p_cost) FROM promotion p WHERE p.p_start_date_sk = d.d_date_sk) AS extra_metric,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_return_amount) DESC) AS row_num,
        COUNT(*) OVER (PARTITION BY d.d_year) AS cnt_per_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND sm.sm_type IN ('OVERNIGHT', 'NEXT DAY')
      AND hd.hd_income_band_sk IN (13, 14)
    GROUP BY d.d_year, d.d_month_seq, sm.sm_type, d.d_date_sk
),
sales_data AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        'SALE' AS trans_type,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        SUM(ws.ws_net_profit) AS net_metric,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'FullPrice' END AS category,
        (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_end_date_sk = d.d_date_sk) AS extra_metric,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS row_num,
        COUNT(*) OVER (PARTITION BY d.d_year) AS cnt_per_year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm2
          WHERE sm2.sm_contract = sm.sm_contract
            AND sm2.sm_type = 'OVERNIGHT'
      )
    GROUP BY d.d_year, d.d_month_seq, p.p_discount_active, d.d_date_sk
)
SELECT *
FROM return_data
UNION ALL
SELECT *
FROM sales_data
ORDER BY year, month_seq, trans_type, total_amount DESC
LIMIT 100
