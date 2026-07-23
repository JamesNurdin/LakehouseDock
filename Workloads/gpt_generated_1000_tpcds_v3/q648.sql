WITH base AS (
    SELECT
        p.p_promo_id AS promo_id,
        sm.sm_ship_mode_id AS ship_mode_id,
        cs.cs_order_number AS cs_order_number,
        ws.ws_order_number AS ws_order_number,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        cc.cc_state,
        cd.cd_credit_rating,
        cd.cd_marital_status,
        ib.ib_upper_bound,
        ws.ws_ext_list_price,
        ws.ws_coupon_amt,
        d_sold.d_year,
        d_ship.d_month_seq,
        p.p_channel_radio
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    WHERE d_sold.d_year = 2002
      AND d_ship.d_month_seq BETWEEN 1200 AND 1220
      AND cc.cc_state = 'CA'
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_marital_status = 'M'
      AND ib.ib_upper_bound <= 50000
      AND ws.ws_ext_list_price > 5000
      AND ws.ws_coupon_amt < 100
      AND p.p_channel_radio = 'N'
),
agg_base AS (
    SELECT
        promo_id,
        ship_mode_id,
        SUM(cs_net_profit) AS sum_cs_profit,
        SUM(ws_net_profit) AS sum_ws_profit,
        COUNT(DISTINCT cs_order_number) AS cs_order_cnt,
        COUNT(DISTINCT ws_order_number) AS ws_order_cnt
    FROM base
    GROUP BY promo_id, ship_mode_id
)
SELECT
    promo_id,
    SUM(sum_cs_profit + sum_ws_profit) AS total_net_profit,
    SUM(cs_order_cnt) AS total_cs_orders,
    SUM(ws_order_cnt) AS total_ws_orders,
    AVG(sum_cs_profit + sum_ws_profit) AS avg_profit_per_ship_mode
FROM agg_base
GROUP BY promo_id
HAVING SUM(sum_cs_profit + sum_ws_profit) > 100000
ORDER BY total_net_profit DESC
LIMIT 100
