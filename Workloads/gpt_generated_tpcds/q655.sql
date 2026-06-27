WITH sales_agg AS (
    SELECT
        t.t_hour,
        sm.sm_ship_mode_id,
        i.i_brand,
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amt,
        COUNT(*) AS order_count,
        COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_bill_customers,
        COUNT(DISTINCT c_ship.c_customer_sk) AS distinct_ship_customers,
        AVG(hd.hd_income_band_sk) AS avg_income_band,
        AVG(c_bill.c_birth_year) AS avg_birth_year
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    LEFT JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    GROUP BY
        t.t_hour,
        sm.sm_ship_mode_id,
        i.i_brand,
        p.p_promo_name
)
SELECT
    t_hour,
    sm_ship_mode_id,
    i_brand,
    p_promo_name,
    total_net_paid,
    total_net_profit,
    total_discount_amt,
    order_count,
    distinct_bill_customers,
    distinct_ship_customers,
    avg_income_band,
    avg_birth_year
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
