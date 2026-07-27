WITH sales_agg AS (
    SELECT
        sm.sm_carrier,
        hd.hd_buy_potential,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_quantity) AS avg_qty,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE c.c_first_shipto_date_sk = 2451068
      AND c.c_last_review_date = 2452430
      AND ws.ws_ext_sales_price > 500
      AND ws.ws_list_price BETWEEN 50 AND 200
      AND sm.sm_carrier = 'FEDEX'
      AND ws.ws_quantity >= 2
    GROUP BY sm.sm_carrier, hd.hd_buy_potential
)
SELECT
    sm_carrier,
    hd_buy_potential,
    total_sales,
    avg_qty,
    order_cnt,
    SUM(total_sales) OVER (ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
