WITH sales_agg AS (
    SELECT
        ws_sold_time_sk,
        ws_bill_hdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_qty
    FROM web_sales
    WHERE ws_ext_sales_price > 1000
      AND ws_quantity > 0
    GROUP BY ws_sold_time_sk, ws_bill_hdemo_sk
)
SELECT
    td.t_shift,
    hd.hd_income_band_sk,
    sa.total_sales,
    sa.total_qty,
    (
        SELECT MAX(DISTINCT ws3.ws_ext_list_price)
        FROM web_sales ws3
        WHERE ws3.ws_bill_hdemo_sk = hd.hd_demo_sk
    ) AS max_list_price_for_demo,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM web_sales ws4
            WHERE ws4.ws_ship_hdemo_sk = hd.hd_demo_sk
              AND ws4.ws_ext_discount_amt > 50
        ) THEN 'HighDiscount'
        ELSE 'LowDiscount'
    END AS discount_flag
FROM sales_agg sa
JOIN time_dim td ON sa.ws_sold_time_sk = td.t_time_sk
JOIN household_demographics hd ON sa.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE td.t_shift IN ('first', 'second')
  AND hd.hd_income_band_sk BETWEEN 5 AND 20
  AND sa.total_sales > 5000
ORDER BY sa.total_sales DESC
LIMIT 100
