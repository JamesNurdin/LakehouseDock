WITH filtered_hd AS (
    SELECT hd_demo_sk, hd_income_band_sk
    FROM household_demographics
    WHERE hd_income_band_sk >= 10
      AND hd_buy_potential LIKE '%10000%'
),
filtered_warehouse AS (
    SELECT *
    FROM warehouse
    WHERE w_warehouse_sq_ft BETWEEN 600000 AND 900000
      AND w_country = 'United States'
      AND w_warehouse_sk IN (
          SELECT w_warehouse_sk FROM warehouse
          EXCEPT
          SELECT w_warehouse_sk FROM warehouse WHERE w_county = 'Ziebach County'
      )
),
cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_bill_hdemo_sk,
        cs.cs_warehouse_sk,
        hd.hd_income_band_sk
    FROM catalog_sales cs
    JOIN filtered_hd hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_quantity > 5
      AND cs.cs_ext_sales_price > 100
      AND cs.cs_bill_addr_sk IN (
          SELECT cs_bill_addr_sk FROM catalog_sales WHERE cs_quantity < 20
      )
      AND cs.cs_sold_time_sk IN (
          SELECT ws_sold_time_sk FROM web_sales WHERE ws_quantity > 2
      )
),
ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_bill_hdemo_sk,
        ws.ws_warehouse_sk,
        hd2.hd_income_band_sk
    FROM web_sales ws
    JOIN filtered_hd hd2
        ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    WHERE ws.ws_quantity > 3
      AND ws.ws_list_price > 20
      AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
      AND ws.ws_ship_mode_sk IS NOT NULL
),
full_cs_wh AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_bill_hdemo_sk,
        cs.cs_warehouse_sk,
        cs.hd_income_band_sk,
        w.w_warehouse_sk,
        w.w_country,
        w.w_warehouse_sq_ft
    FROM cs
    FULL OUTER JOIN filtered_warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
),
joined AS (
    SELECT
        COALESCE(fc.cs_order_number, ws.ws_order_number) AS order_number,
        COALESCE(fc.w_warehouse_sk, ws.ws_warehouse_sk) AS warehouse_sk,
        COALESCE(fc.w_country, w2.w_country) AS country,
        COALESCE(fc.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0) AS total_sales,
        COALESCE(fc.cs_quantity, 0) + COALESCE(ws.ws_quantity, 0) AS total_quantity,
        COALESCE(fc.w_warehouse_sq_ft, w2.w_warehouse_sq_ft) AS warehouse_sq_ft,
        COALESCE(fc.hd_income_band_sk, ws.hd_income_band_sk) AS income_band_sk
    FROM full_cs_wh fc
    LEFT JOIN ws
        ON fc.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN filtered_warehouse w2
        ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    WHERE (fc.cs_ext_sales_price IS NOT NULL OR ws.ws_ext_sales_price IS NOT NULL)
),
final AS (
    SELECT
        j.*,
        (SELECT SUM(wr.wr_return_amt)
         FROM web_returns wr
         WHERE wr.wr_order_number = j.order_number) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY j.country ORDER BY j.total_sales DESC) AS sales_rank
    FROM joined j
    WHERE j.total_sales > 200
      AND j.warehouse_sq_ft BETWEEN 600000 AND 900000
      AND j.income_band_sk IS NOT NULL
      AND EXISTS (
          SELECT 1 FROM web_returns wr2
          WHERE wr2.wr_order_number = j.order_number
            AND wr2.wr_return_amt > 0
      )
)
SELECT
    order_number,
    warehouse_sk,
    country,
    total_sales,
    total_quantity,
    total_return_amount,
    sales_rank
FROM final
ORDER BY sales_rank
LIMIT 100
