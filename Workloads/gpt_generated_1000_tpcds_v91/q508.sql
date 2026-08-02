WITH store_item_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_item_sk
),
item_sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(*) AS web_cnt
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
joined AS (
    SELECT
        st.s_store_sk,
        st.s_store_name,
        i.i_product_name,
        CONCAT(st.s_store_name, ' - ', i.i_product_name) AS store_product,
        regexp_extract(i.i_product_name, '([0-9]{3})$', 1) AS product_suffix,
        COALESCE(sir.total_return_loss, 0) AS total_return_loss,
        COALESCE(isales.total_web_profit, 0) AS total_web_profit,
        (COALESCE(sir.total_return_loss, 0) + COALESCE(isales.total_web_profit, 0)) AS net_profit,
        CASE 
            WHEN (COALESCE(sir.total_return_loss, 0) + COALESCE(isales.total_web_profit, 0)) > 0 THEN 'Profitable'
            ELSE 'Unprofitable'
        END AS profit_status,
        ROW_NUMBER() OVER (PARTITION BY st.s_store_sk ORDER BY (COALESCE(sir.total_return_loss, 0) + COALESCE(isales.total_web_profit, 0)) DESC) AS profit_rank
    FROM store st
    JOIN store_item_returns sir ON st.s_store_sk = sir.sr_store_sk
    JOIN item i ON sir.sr_item_sk = i.i_item_sk
    LEFT JOIN item_sales isales ON i.i_item_sk = isales.ws_item_sk
    WHERE
        st.s_store_name LIKE '%Market%'
        AND regexp_like(i.i_product_name, '^[A-Za-z]+[0-9]{3}$')
        AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            JOIN ship_mode sm ON ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk
            WHERE ws2.ws_item_sk = i.i_item_sk
              AND ws2.ws_coupon_amt > 1000
              AND sm.sm_type LIKE '%AIR%'
        )
)
SELECT
    profit_rank,
    s_store_name,
    i_product_name,
    store_product,
    product_suffix,
    net_profit,
    profit_status,
    total_return_loss,
    total_web_profit
FROM joined
WHERE profit_rank <= 10
ORDER BY s_store_name, profit_rank
LIMIT 100
