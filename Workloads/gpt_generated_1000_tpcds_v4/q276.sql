WITH avg_discount_per_item AS (
    SELECT ws_item_sk, AVG(ws_ext_discount_amt) AS avg_discount
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_year_profit AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_profit,
        avg_discount_per_item.avg_discount
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN avg_discount_per_item
        ON i.i_item_sk = avg_discount_per_item.ws_item_sk
    WHERE
        d.d_year = 2001
        AND i.i_current_price BETWEEN 10 AND 100
        AND inv.inv_quantity_on_hand > 100
        AND sm.sm_type = 'AIR'
        AND wp.wp_link_count >= 5
        AND ws.ws_ext_discount_amt > 200
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        avg_discount_per_item.avg_discount
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    d_year,
    store_profit,
    web_profit,
    total_profit,
    CASE WHEN avg_discount > 500 THEN 'High Discount' ELSE 'Low Discount' END AS discount_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM customer_year_profit
ORDER BY profit_rank
LIMIT 100
