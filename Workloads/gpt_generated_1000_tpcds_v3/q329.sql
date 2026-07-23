WITH
    store_sales_agg AS (
        SELECT
            ss_item_sk,
            ss_cdemo_sk,
            ss_hdemo_sk,
            SUM(ss_net_paid) AS store_net_paid,
            SUM(ss_net_profit) AS store_net_profit,
            SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_sk, ss_cdemo_sk, ss_hdemo_sk
    ),
    web_sales_agg AS (
        SELECT
            ws_item_sk,
            ws_bill_cdemo_sk,
            ws_ship_cdemo_sk,
            ws_bill_hdemo_sk,
            ws_ship_hdemo_sk,
            ws_web_page_sk,
            ws_web_site_sk,
            SUM(ws_net_paid) AS web_net_paid,
            SUM(ws_net_profit) AS web_net_profit,
            SUM(ws_quantity) AS web_quantity
        FROM web_sales
        GROUP BY ws_item_sk, ws_bill_cdemo_sk, ws_ship_cdemo_sk, ws_bill_hdemo_sk, ws_ship_hdemo_sk, ws_web_page_sk, ws_web_site_sk
    ),
    high_volume_items AS (
        SELECT ss_item_sk AS i_item_sk
        FROM store_sales
        GROUP BY ss_item_sk
        HAVING SUM(ss_quantity) > 1000
        UNION
        SELECT ws_item_sk
        FROM web_sales
        GROUP BY ws_item_sk
        HAVING SUM(ws_quantity) > 1000
    ),
    avg_item_price_cte AS (
        SELECT AVG(i_current_price) AS avg_price
        FROM item
    )
SELECT
    i_store.i_item_id,
    i_store.i_product_name,
    cd_store.cd_gender AS customer_gender,
    hd_store.hd_buy_potential AS household_buy_potential,
    SUM(ssa.store_net_paid) AS total_store_sales,
    SUM(wsa.web_net_paid) AS total_web_sales,
    SUM(ssa.store_net_paid) + SUM(wsa.web_net_paid) AS total_sales,
    SUM(ssa.store_net_profit) + SUM(wsa.web_net_profit) AS total_profit,
    CASE
        WHEN (SUM(ssa.store_net_profit) + SUM(wsa.web_net_profit)) > 10000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    CASE
        WHEN i_store.i_current_price > (SELECT avg_price FROM avg_item_price_cte) THEN 'Above Avg Price'
        ELSE 'Below Avg Price'
    END AS price_comparison
FROM store_sales_agg ssa
JOIN web_sales_agg wsa
    ON ssa.ss_item_sk = wsa.ws_item_sk
JOIN item i_store
    ON i_store.i_item_sk = ssa.ss_item_sk
JOIN item i_web
    ON i_web.i_item_sk = wsa.ws_item_sk
JOIN customer_demographics cd_store
    ON cd_store.cd_demo_sk = ssa.ss_cdemo_sk
JOIN household_demographics hd_store
    ON hd_store.hd_demo_sk = ssa.ss_hdemo_sk
JOIN customer_demographics cd_bill
    ON cd_bill.cd_demo_sk = wsa.ws_bill_cdemo_sk
JOIN customer_demographics cd_ship
    ON cd_ship.cd_demo_sk = wsa.ws_ship_cdemo_sk
JOIN household_demographics hd_bill
    ON hd_bill.hd_demo_sk = wsa.ws_bill_hdemo_sk
JOIN household_demographics hd_ship
    ON hd_ship.hd_demo_sk = wsa.ws_ship_hdemo_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = wsa.ws_web_page_sk
JOIN web_site ws
    ON ws.web_site_sk = wsa.ws_web_site_sk
WHERE i_store.i_item_sk IN (SELECT i_item_sk FROM high_volume_items)
GROUP BY
    i_store.i_item_id,
    i_store.i_product_name,
    cd_store.cd_gender,
    hd_store.hd_buy_potential,
    i_store.i_current_price
HAVING (SUM(ssa.store_net_paid) + SUM(wsa.web_net_paid)) > 5000
ORDER BY total_sales DESC
LIMIT 100
