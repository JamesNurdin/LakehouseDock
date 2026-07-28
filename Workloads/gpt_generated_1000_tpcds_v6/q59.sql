WITH ss AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM store_sales ss
    WHERE ss.ss_quantity > 5
      AND ss.ss_sales_price > 100
      AND ss.ss_sold_date_sk BETWEEN 2450950 AND 2451050
),
agg AS (
    SELECT
        i.i_category,
        s.s_state,
        ws.ws_web_site_sk,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        AVG(ws.ws_ext_ship_cost) AS avg_web_ship_cost,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
        MIN(ss.ss_sales_price) AS min_store_sales_price,
        MAX(ws.ws_net_profit) AS max_web_profit,
        CASE
            WHEN i.i_category = 'Electronics' THEN 'Tech'
            WHEN i.i_category = 'Shoes'       THEN 'Apparel'
            ELSE 'Other'
        END AS category_group
    FROM ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    WHERE i.i_units = 'Lb        '
      AND cd.cd_gender = 'M'
      AND s.s_state = 'CA'
      AND web.web_state = 'NY'
    GROUP BY
        i.i_category,
        s.s_state,
        ws.ws_web_site_sk,
        CASE
            WHEN i.i_category = 'Electronics' THEN 'Tech'
            WHEN i.i_category = 'Shoes'       THEN 'Apparel'
            ELSE 'Other'
        END
)
SELECT
    i_category,
    s_state,
    ws_web_site_sk,
    total_store_net_paid,
    avg_web_ship_cost,
    store_ticket_cnt,
    min_store_sales_price,
    max_web_profit,
    category_group,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_store_net_paid DESC) AS category_rank
FROM agg
ORDER BY total_store_net_paid DESC
LIMIT 100
