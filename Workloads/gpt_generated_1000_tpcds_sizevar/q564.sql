WITH item_sample AS (
        SELECT *
        FROM item
        TABLESAMPLE BERNOULLI (10) -- sample 10% of items
    ),
    ws_agg AS (
        SELECT ws_item_sk,
               SUM(ws_net_profit) AS total_profit,
               COUNT(*) AS sales_cnt
        FROM web_sales
        GROUP BY ws_item_sk
    )
SELECT DISTINCT
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_vehicle_count,
    ib.ib_upper_bound,
    i.i_item_id,
    i.i_current_price,
    ws_agg.total_profit,
    ws_agg.sales_cnt,
    sr.sr_return_amt,
    wr.wr_fee,
    (
        SELECT COUNT(DISTINCT sr2.sr_ticket_number)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
    ) AS store_return_cnt
FROM store_returns sr
JOIN item_sample i ON sr.sr_item_sk = i.i_item_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ws_agg ON i.i_item_sk = ws_agg.ws_item_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
WHERE
    c.c_birth_year = 1955
    AND cd.cd_gender = 'M'
    AND hd.hd_vehicle_count >= 2
    AND ib.ib_lower_bound = 10001
    AND i.i_current_price > 75.00
    AND wr.wr_fee > 50.00
    AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = sr.sr_item_sk
    )
LIMIT 100
