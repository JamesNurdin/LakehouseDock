WITH joined AS (
    SELECT
        ss.ss_store_sk,
        d_ss.d_date,
        ss.ss_ext_sales_price AS store_sales_amount,
        ws.ws_ext_sales_price AS web_sales_amount,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_net_profit AS web_net_profit,
        sr.sr_fee,
        sr.sr_store_credit,
        cp.cp_catalog_page_number,
        ws.ws_quantity AS web_quantity,
        ss.ss_quantity AS store_quantity
    FROM store_sales ss
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_ss.d_date_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ss.d_date_sk
        AND cp.cp_end_date_sk = d_ss.d_date_sk
    WHERE d_ss.d_year = 2000
      AND d_ss.d_month_seq BETWEEN 1200 AND 1300
      AND d_sr.d_year = 2000
      AND d_ws_ship.d_year = 2000
      AND sr.sr_fee > 20
      AND sr.sr_store_credit < 100
      AND cp.cp_catalog_page_number IN (9, 12, 15)
      AND ws.ws_quantity >= 5
)
SELECT
    ss_store_sk,
    d_date,
    (store_sales_amount + web_sales_amount) AS total_sales,
    (store_net_profit + web_net_profit) AS total_profit,
    CASE
        WHEN sr_fee > 50 THEN 'High'
        ELSE 'Low'
    END AS fee_category,
    ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY (store_sales_amount + web_sales_amount) DESC) AS sales_rank
FROM joined
ORDER BY total_sales DESC
LIMIT 100
