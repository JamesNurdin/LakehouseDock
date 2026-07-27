WITH joined_data AS (
    SELECT
        store.s_store_id,
        store_sales.ss_net_profit,
        catalog_sales.cs_net_profit,
        web_sales.ws_net_profit,
        store_returns.sr_net_loss,
        web_returns.wr_net_loss
    FROM store_sales
    JOIN item ON store_sales.ss_item_sk = item.i_item_sk
    JOIN store ON store_sales.ss_store_sk = store.s_store_sk
    JOIN customer ON store_sales.ss_customer_sk = customer.c_customer_sk
    JOIN household_demographics ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
    JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    JOIN inventory ON item.i_item_sk = inventory.inv_item_sk
    JOIN store_returns ON store_sales.ss_ticket_number = store_returns.sr_ticket_number
    JOIN catalog_sales ON catalog_sales.cs_item_sk = item.i_item_sk
    JOIN call_center ON catalog_sales.cs_call_center_sk = call_center.cc_call_center_sk
    JOIN web_sales ON web_sales.ws_item_sk = item.i_item_sk
    JOIN web_page ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
    JOIN web_returns ON web_returns.wr_order_number = web_sales.ws_order_number
    WHERE inventory.inv_quantity_on_hand > 500
      AND income_band.ib_upper_bound >= 100000
      AND store.s_floor_space BETWEEN 20000 AND 50000
      AND item.i_current_price BETWEEN 10 AND 100
      AND customer.c_birth_year BETWEEN 1960 AND 1980
      AND catalog_sales.cs_quantity > 5
      AND web_returns.wr_return_quantity < 50
),
per_store AS (
    SELECT
        s_store_id,
        SUM(COALESCE(ss_net_profit, 0) + COALESCE(cs_net_profit, 0) + COALESCE(ws_net_profit, 0) - COALESCE(sr_net_loss, 0) - COALESCE(wr_net_loss, 0)) AS total_profit
    FROM joined_data
    GROUP BY s_store_id
)
SELECT
    s_store_id,
    total_profit
FROM per_store
WHERE total_profit > (SELECT AVG(total_profit) FROM per_store)
ORDER BY total_profit DESC
LIMIT 100
