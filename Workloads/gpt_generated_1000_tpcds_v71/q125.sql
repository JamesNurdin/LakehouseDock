WITH ss_filtered AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_quantity,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_net_profit > 50
      AND ss.ss_quantity BETWEEN 1 AND 5
      AND ss.ss_sold_date_sk BETWEEN 2452000 AND 2452500
),
inv_filtered AS (
    SELECT inv.inv_item_sk, inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 10
),
item_filtered AS (
    SELECT i.i_item_sk, i.i_product_name, i.i_category, i.i_current_price, i.i_brand
    FROM item i
    WHERE i.i_current_price BETWEEN 20 AND 300
),
cust_filtered AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_hdemo_sk
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
),
hd_filtered AS (
    SELECT hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_buy_potential
    FROM household_demographics hd
    WHERE hd.hd_income_band_sk IN (2, 3, 4)
),
store_filtered AS (
    SELECT s.s_store_sk, s.s_store_name, s.s_state, s.s_gmt_offset
    FROM store s
    WHERE s.s_state IN ('OH', 'CA', 'TX')
)
SELECT
    s.s_store_name,
    s.s_state,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    ss.ss_sold_date_sk,
    ss.ss_quantity,
    ss.ss_net_profit,
    inv.inv_quantity_on_hand,
    c.c_first_name,
    c.c_last_name,
    hd.hd_income_band_sk,
    RANK() OVER (PARTITION BY s.s_state ORDER BY ss.ss_net_profit DESC) AS profit_rank_state,
    SUM(ss.ss_net_profit) OVER (
        PARTITION BY s.s_store_sk
        ORDER BY ss.ss_sold_date_sk
        ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
    ) AS profit_last_30_days
FROM ss_filtered ss
JOIN item_filtered i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store_filtered s
    ON ss.ss_store_sk = s.s_store_sk
JOIN cust_filtered c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN hd_filtered hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN inv_filtered inv
    ON i.i_item_sk = inv.inv_item_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    WHERE ws.ws_item_sk = ss.ss_item_sk
      AND ws.ws_net_paid > 500
      AND ws.ws_ship_date_sk BETWEEN 2452000 AND 2452500
)
ORDER BY s.s_state, profit_rank_state
LIMIT 100
