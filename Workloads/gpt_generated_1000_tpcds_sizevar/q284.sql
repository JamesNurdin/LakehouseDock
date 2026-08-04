WITH ss_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT *
FROM (
    SELECT
        d.d_year,
        d.d_month_seq,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_level,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_web_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
        MIN(inv.inv_quantity_on_hand) AS min_inventory_qty,
        MAX(wh.w_warehouse_sq_ft) AS max_warehouse_sqft
    FROM ss_sample ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse wh ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1200 AND 1240
        AND d.d_weekend = 'N'
        AND d.d_holiday = 'N'
        AND ss.ss_quantity > 2
        AND ss.ss_ext_sales_price > 1000
        AND inv.inv_quantity_on_hand BETWEEN 10 AND 500
        AND wh.w_state = 'CA'
        AND ws.ws_net_profit > 0
        AND EXISTS (
            SELECT 1 FROM web_sales ws2
            WHERE ws2.ws_item_sk = ss.ss_item_sk
              AND ws2.ws_net_profit > 50
        )
    GROUP BY d.d_year, d.d_month_seq
    HAVING SUM(ss.ss_ext_sales_price) > 5000
) AS q1
UNION DISTINCT
SELECT *
FROM (
    SELECT
        d.d_year,
        d.d_month_seq,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 150000 THEN 'VERY_HIGH' ELSE 'MODERATE' END AS sales_level,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_web_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
        MIN(inv.inv_quantity_on_hand) AS min_inventory_qty,
        MAX(wh.w_warehouse_sq_ft) AS max_warehouse_sqft
    FROM ss_sample ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse wh ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1241 AND 1280
        AND d.d_weekend = 'N'
        AND d.d_holiday = 'N'
        AND ss.ss_quantity > 5
        AND ss.ss_ext_sales_price > 2000
        AND inv.inv_quantity_on_hand BETWEEN 20 AND 400
        AND wh.w_state = 'CA'
        AND ws.ws_net_profit > 10
        AND EXISTS (
            SELECT 1 FROM web_sales ws2
            WHERE ws2.ws_item_sk = ss.ss_item_sk
              AND ws2.ws_net_profit > 100
        )
    GROUP BY d.d_year, d.d_month_seq
    HAVING SUM(ss.ss_ext_sales_price) > 10000
) AS q2
ORDER BY total_sales DESC
LIMIT 100
