WITH
union_items AS (
    SELECT i_item_sk, i_category, i_current_price
    FROM item
    WHERE i_category_id = 6
    UNION
    SELECT i_item_sk, i_category, i_current_price
    FROM item
    WHERE i_category_id = 8
),
store_sales_full AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        s.s_state,
        s.s_store_name
    FROM store s
    FULL OUTER JOIN store_sales ss
        ON s.s_store_sk = ss.ss_store_sk
),
joined_data AS (
    SELECT
        dd.d_date,
        dd.d_year,
        ui.i_category,
        ui.i_current_price,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        ssf.s_state,
        ssf.s_store_name,
        ssf.ss_quantity,
        ssf.ss_net_profit,
        ws.ws_order_number,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        ROW_NUMBER() OVER (PARTITION BY dd.d_date ORDER BY ws.ws_net_profit DESC) AS rn_per_day,
        CASE 
            WHEN ws.ws_net_profit > (SELECT AVG(ss_net_profit) FROM store_sales) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS profit_category
    FROM date_dim dd
    JOIN store_sales_full ssf ON ssf.ss_sold_date_sk = dd.d_date_sk
    JOIN union_items ui ON ui.i_item_sk = ssf.ss_item_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = ssf.ss_hdemo_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = ui.i_item_sk
        AND ws.ws_sold_date_sk = dd.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE dd.d_year = 2001
      AND ui.i_category IN ('infants', 'toddlers')
      AND hd.hd_income_band_sk IN (1, 7, 11)
      AND ssf.s_state = 'CA'
      AND ssf.ss_quantity > 5
      AND ws.ws_net_profit > 0
      AND wr.wr_return_quantity IS NOT NULL
)
SELECT
    d_date,
    d_year,
    i_category,
    i_current_price,
    hd_income_band_sk,
    hd_vehicle_count,
    s_state,
    s_store_name,
    ss_quantity,
    ss_net_profit,
    ws_order_number,
    ws_net_profit,
    wr_return_quantity,
    wr_net_loss,
    rn_per_day,
    profit_category
FROM joined_data
WHERE ws_net_profit > (SELECT MAX(ss_net_profit) FROM store_sales)
ORDER BY ss_net_profit DESC
LIMIT 100
