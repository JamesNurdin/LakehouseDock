WITH filtered_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price
    FROM web_sales ws
    WHERE ws.ws_quantity >= 2
      AND ws.ws_sales_price > 20
      AND ws.ws_net_paid_inc_ship_tax > 500
      AND ws.ws_ext_discount_amt > 0
      AND ws.ws_ext_sales_price > 0
)
SELECT
    i.i_category,
    i.i_brand,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd_bill.hd_vehicle_count AS bill_vehicle_count,
    hd_bill.hd_dep_count AS bill_dep_count,
    hd_ship.hd_vehicle_count AS ship_vehicle_count,
    hd_ship.hd_dep_count AS ship_dep_count,
    p.p_promo_name,
    COUNT(*) AS order_count,
    SUM(fs.ws_quantity) AS total_quantity,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    AVG(fs.ws_sales_price) AS avg_sales_price,
    MIN(fs.ws_sales_price) AS min_sales_price,
    MAX(fs.ws_sales_price) AS max_sales_price
FROM filtered_sales fs
JOIN item i
    ON fs.ws_item_sk = i.i_item_sk
JOIN promotion p
    ON fs.ws_promo_sk = p.p_promo_sk
JOIN household_demographics hd_bill
    ON fs.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON fs.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE i.i_current_price BETWEEN 10 AND 100
  AND ib.ib_upper_bound >= 100000
  AND ib.ib_lower_bound <= 150000
  AND hd_bill.hd_vehicle_count >= 2
  AND hd_bill.hd_dep_count <= 5
  AND hd_ship.hd_vehicle_count >= 1
  AND p.p_cost > 500
GROUP BY
    i.i_category,
    i.i_brand,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd_bill.hd_vehicle_count,
    hd_bill.hd_dep_count,
    hd_ship.hd_vehicle_count,
    hd_ship.hd_dep_count,
    p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
