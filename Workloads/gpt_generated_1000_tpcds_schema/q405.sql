WITH sales_union AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        NULL AS ship_date_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_cdemo_sk AS cdemo_sk,
        ss.ss_hdemo_sk AS hdemo_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_sales_price AS sales_price,
        ss.ss_net_profit AS net_profit,
        NULL AS order_number,
        NULL AS ship_mode_sk,
        NULL AS web_page_sk
    FROM store_sales ss
    UNION DISTINCT
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_ship_date_sk AS ship_date_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_bill_cdemo_sk AS cdemo_sk,
        ws.ws_bill_hdemo_sk AS hdemo_sk,
        NULL AS store_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_sales_price AS sales_price,
        ws.ws_net_profit AS net_profit,
        ws.ws_order_number AS order_number,
        ws.ws_ship_mode_sk AS ship_mode_sk,
        ws.ws_web_page_sk AS web_page_sk
    FROM web_sales ws
)
SELECT
    d_sold.d_year AS year,
    s.s_market_desc AS market_desc,
    CASE
        WHEN su.net_profit > 1000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    SUM(su.sales_price) AS total_sales,
    SUM(su.quantity) AS total_quantity,
    COUNT(DISTINCT su.customer_sk) AS unique_customers,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT r.r_reason_id) AS distinct_return_reasons
FROM sales_union su
INNER JOIN date_dim d_sold
    ON su.date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_ship
    ON su.ship_date_sk = d_ship.d_date_sk
INNER JOIN customer c
    ON su.customer_sk = c.c_customer_sk
INNER JOIN customer_demographics cd
    ON su.cdemo_sk = cd.cd_demo_sk
INNER JOIN household_demographics hd
    ON su.hdemo_sk = hd.hd_demo_sk
FULL OUTER JOIN store s
    ON su.store_sk = s.s_store_sk
INNER JOIN promotion p
    ON su.promo_sk = p.p_promo_sk
INNER JOIN inventory i
    ON i.inv_date_sk = d_sold.d_date_sk
LEFT JOIN web_page wp
    ON su.web_page_sk = wp.wp_web_page_sk
LEFT JOIN ship_mode sm
    ON su.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_returns wr
    ON su.order_number = wr.wr_order_number
LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2002
GROUP BY
    d_sold.d_year,
    s.s_market_desc,
    CASE
        WHEN su.net_profit > 1000 THEN 'High'
        ELSE 'Low'
    END
ORDER BY total_sales DESC
LIMIT 100
