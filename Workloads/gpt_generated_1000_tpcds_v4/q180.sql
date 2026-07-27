WITH sales_returns AS (
    SELECT
        c.c_customer_id,
        c.c_current_hdemo_sk,
        hd.hd_income_band_sk,
        sm.sm_code,
        w.w_state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    INNER JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    INNER JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    WHERE
        sm.sm_code = 'AIR'                                   -- filter 1: ship mode
        AND w.w_state = 'CA'                                 -- filter 2: warehouse location
        AND c.c_birth_year >= 1970                           -- filter 3: customer age
        AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = ws.ws_promo_sk
              AND p.p_discount_active = 'Y'                -- semi‑join filter on promotion
        )
    GROUP BY
        c.c_customer_id,
        c.c_current_hdemo_sk,
        hd.hd_income_band_sk,
        sm.sm_code,
        w.w_state
)
SELECT
    c_current_hdemo_sk,
    hd_income_band_sk,
    AVG(total_sales) AS avg_total_sales,
    AVG(total_returns) AS avg_total_returns,
    COUNT(*) AS customer_cnt
FROM sales_returns
WHERE sales_rank = 1               -- keep only the top‑ranked sale per customer
GROUP BY
    c_current_hdemo_sk,
    hd_income_band_sk
ORDER BY avg_total_sales DESC
LIMIT 100
