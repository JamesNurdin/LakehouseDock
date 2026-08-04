WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_qty,
        AVG(cs.cs_coupon_amt) AS avg_coupon
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
      AND cs.cs_ext_sales_price > 1000
      AND cs.cs_quantity >= 1
      AND cs.cs_ext_discount_amt < 500
      AND cs.cs_ext_tax BETWEEN 0 AND 200
      AND cs.cs_ship_mode_sk IS NOT NULL
    GROUP BY
        cs.cs_order_number,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk
),
returns_agg AS (
    SELECT
        cr.cr_order_number,
        SUM(cr.cr_return_amount) AS total_return,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
      AND cr.cr_return_quantity > 0
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY cr.cr_order_number
)
SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    sm.sm_type,
    p.p_promo_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sa.total_sales,
    sa.total_qty,
    sa.avg_coupon,
    ra.total_return,
    ra.return_cnt,
    (sa.total_sales - COALESCE(ra.total_return, 0)) AS net_sales,
    addr.bill_city,
    addr.bill_state
FROM sales_agg sa
JOIN catalog_page cp
    ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON sa.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd
    ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
    ON sa.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN returns_agg ra
    ON sa.cs_order_number = ra.cr_order_number
CROSS JOIN LATERAL (
    SELECT ca.ca_city AS bill_city, ca.ca_state AS bill_state
) AS addr
WHERE cp.cp_type = 'Home'
  AND sm.sm_carrier = 'FedEx'
  AND p.p_discount_active = 'Y'
  AND hd.hd_vehicle_count >= 1
  AND ib.ib_lower_bound >= 50000
  AND ca.ca_country = 'United States'
ORDER BY net_sales DESC
LIMIT 100
