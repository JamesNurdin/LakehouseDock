WITH per_day AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        i.i_category,
        i.i_brand,
        SUM(ws.ws_ext_sales_price) AS day_sales,
        SUM(ws.ws_net_profit) AS day_profit
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = ws.ws_item_sk
        AND inv.inv_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = ws.ws_item_sk
        AND cr.cr_returned_time_sk = ws.ws_sold_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ws.ws_item_sk
        AND sr.sr_return_time_sk = ws.ws_sold_time_sk
    WHERE ws.ws_item_sk IN (
            SELECT i_item_sk FROM item WHERE i_brand = 'BrandX'
        )
        AND t.t_shift = 'first'
        AND i.i_container = 'Unknown'
        AND w.w_state = 'CA'
        AND w.w_city = 'Los Angeles'
        AND cd.cd_gender = 'M'
        AND hd.hd_buy_potential = '1000-5000'
        AND inv.inv_quantity_on_hand > 10
        AND ib.ib_upper_bound >= 50000
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk, i.i_category, i.i_brand
)
SELECT
    pd.ws_item_sk,
    pd.i_category,
    pd.i_brand,
    SUM(pd.day_sales) AS total_sales,
    AVG(pd.day_sales) AS avg_daily_sales,
    SUM(pd.day_profit) AS total_profit
FROM per_day pd
CROSS JOIN LATERAL (
    SELECT AVG(ws2.ws_ext_sales_price) AS avg_price_overall
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = pd.ws_item_sk
) l
WHERE l.avg_price_overall > 50
GROUP BY pd.ws_item_sk, pd.i_category, pd.i_brand
HAVING SUM(pd.day_sales) > 20000
ORDER BY total_profit DESC
LIMIT 100
