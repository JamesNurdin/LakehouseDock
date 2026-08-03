WITH joined AS (
    SELECT
        cp.cp_catalog_page_id,
        d.d_date,
        d.d_year AS d_year,
        d.d_day_name,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        w.w_warehouse_sk,
        w.w_warehouse_name AS w_warehouse_name,
        w.w_zip,
        w.w_county,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        site.web_site_id
    FROM date_dim d
    FULL OUTER JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE d.d_day_name = 'Monday'
      AND w.w_county = 'San Miguel County'
      AND w.w_zip = (SELECT w2.w_zip FROM warehouse w2 WHERE w2.w_warehouse_sk = 10 LIMIT 1)
      AND inv.inv_quantity_on_hand > 0
      AND inv.inv_warehouse_sk IN (
          SELECT inv2.inv_warehouse_sk FROM inventory inv2
          EXCEPT
          SELECT w3.w_warehouse_sk FROM warehouse w3
      )
),
agg1 AS (
    SELECT
        w_warehouse_name AS warehouse_name,
        d_year AS year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM joined
    GROUP BY w_warehouse_name, d_year
)
SELECT
    warehouse_name,
    year,
    total_sales,
    total_qty,
    total_sales / NULLIF(total_qty, 0) AS avg_price_per_qty,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
FROM agg1
WHERE total_sales > 1000
ORDER BY total_sales DESC
LIMIT 100
