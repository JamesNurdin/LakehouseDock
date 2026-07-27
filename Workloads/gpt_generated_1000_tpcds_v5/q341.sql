WITH sales_agg AS (
    SELECT
        ws_item_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_qty,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_ext_sales_price > 100
      AND ws_quantity BETWEEN 1 AND 100
      AND ws_coupon_amt < 5000
      AND ws_ship_mode_sk IS NOT NULL
      AND ws_warehouse_sk IS NOT NULL
    GROUP BY ws_item_sk, ws_ship_mode_sk, ws_warehouse_sk, ws_bill_cdemo_sk
)
SELECT
    sm.sm_carrier,
    w.w_warehouse_name,
    cd.cd_gender,
    i.i_item_id,
    i.i_product_name,
    SUM(sa.total_sales) AS carrier_sales,
    SUM(sa.total_qty) AS carrier_qty,
    CASE
        WHEN SUM(sa.total_sales) = 0 THEN 0
        ELSE SUM(sa.total_profit) / SUM(sa.total_sales)
    END AS profit_margin,
    (
        SELECT AVG(i2.i_current_price)
        FROM item i2
        WHERE i2.i_brand_id = i.i_brand_id
    ) AS brand_avg_price
FROM sales_agg sa
JOIN item i
    ON sa.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON sa.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON sa.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
    ON sa.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE i.i_units = 'Carton'
  AND sm.sm_carrier IN ('DHL', 'FEDEX')
  AND w.w_state = 'CA'
  AND cd.cd_education_status = 'College'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = sa.ws_item_sk
          AND ws2.ws_ext_discount_amt > 50
      )
GROUP BY sm.sm_carrier, w.w_warehouse_name, cd.cd_gender, i.i_item_id, i.i_product_name, i.i_brand_id
HAVING SUM(sa.total_sales) > 1000
ORDER BY carrier_sales DESC
LIMIT 100
