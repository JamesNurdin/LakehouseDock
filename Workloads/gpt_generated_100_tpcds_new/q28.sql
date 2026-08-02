WITH high_income_demo AS (
    SELECT hd_demo_sk, hd_buy_potential
    FROM household_demographics
    WHERE hd_income_band_sk >= 5
),
catalog_sub AS (
    SELECT
        c.c_customer_id,
        cs.cs_order_number      AS order_number,
        cs.cs_net_profit        AS profit,
        cc.cc_name              AS cc_name,
        w.w_warehouse_name      AS warehouse_name,
        hd.hd_buy_potential     AS hd_buy_potential
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN high_income_demo hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_net_profit > 1000
      AND cc.cc_state = 'CA'
      AND w.w_warehouse_sq_ft > 500000
),
store_sub AS (
    SELECT
        c.c_customer_id,
        ss.ss_ticket_number     AS order_number,
        ss.ss_net_profit        AS profit,
        CAST(NULL AS varchar)   AS cc_name,
        CAST(NULL AS varchar)   AS warehouse_name,
        hd.hd_buy_potential     AS hd_buy_potential
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN high_income_demo hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_net_profit > 1000
      AND c.c_birth_country = 'United States'
)
SELECT *
FROM catalog_sub
INTERSECT
SELECT *
FROM store_sub
ORDER BY profit DESC, c_customer_id
LIMIT 100
