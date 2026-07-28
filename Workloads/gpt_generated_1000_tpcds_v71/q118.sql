WITH sold_agg AS (
    SELECT
        d_sold.d_year,
        cc.cc_state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        MIN(ws.ws_ext_sales_price) AS min_sale,
        MAX(ws.ws_ext_sales_price) AS max_sale
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
      ON cc.cc_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND cc.cc_country = 'United States'
      AND cc.cc_hours = '8AM-4PM             '
      AND ws.ws_ext_discount_amt > 1000
      AND ws.ws_ext_ship_cost < 2000
      AND NOT EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = ws.ws_item_sk
              AND inv.inv_date_sk = d_sold.d_date_sk
              AND inv.inv_quantity_on_hand = 0
      )
    GROUP BY d_sold.d_year, cc.cc_state
),
shipped_agg AS (
    SELECT
        d_ship.d_year,
        cc.cc_state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        MIN(ws.ws_ext_sales_price) AS min_sale,
        MAX(ws.ws_ext_sales_price) AS max_sale
    FROM web_sales ws
    JOIN date_dim d_ship
      ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN call_center cc
      ON cc.cc_open_date_sk = d_ship.d_date_sk
    WHERE d_ship.d_year = 2002
      AND cc.cc_country = 'United States'
      AND cc.cc_hours = '8AM-8AM             '
      AND ws.ws_ext_discount_amt BETWEEN 500 AND 1500
      AND ws.ws_ext_ship_cost > 100
      AND NOT EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = ws.ws_item_sk
              AND inv.inv_date_sk = d_ship.d_date_sk
              AND inv.inv_quantity_on_hand < 10
      )
    GROUP BY d_ship.d_year, cc.cc_state
)
SELECT *
FROM (
    SELECT 'Sold' AS period_type,
           d_year,
           cc_state,
           total_sales,
           avg_discount,
           order_cnt,
           min_sale,
           max_sale
    FROM sold_agg
    UNION ALL
    SELECT 'Shipped' AS period_type,
           d_year,
           cc_state,
           total_sales,
           avg_discount,
           order_cnt,
           min_sale,
           max_sale
    FROM shipped_agg
) combined
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
