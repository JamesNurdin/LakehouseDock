/* goal: Identify top warehouses and promotions for the year 2001 based on combined catalog and web net sales, segmented by order size, while excluding any orders that also appear in the web_sales table. */
WITH base AS (
    SELECT
        w.w_warehouse_name AS w_warehouse_name,
        p.p_promo_name    AS p_promo_name,
        ds_sold.d_year    AS year,
        CASE WHEN cs.cs_quantity > 5 THEN 'large' ELSE 'small' END AS order_size,
        cs.cs_order_number AS cs_order_number,
        cs.cs_net_paid    AS cs_net_paid,
        ws.ws_net_paid    AS ws_net_paid,
        i.inv_quantity_on_hand AS inv_qty
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim ds_sold
      ON cs.cs_sold_date_sk = ds_sold.d_date_sk
    JOIN date_dim ds_ship
      ON cs.cs_ship_date_sk = ds_ship.d_date_sk
    JOIN inventory i
      ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim di
      ON i.inv_date_sk = di.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = ds_ship.d_date_sk
    JOIN web_sales ws
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
     AND ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim ws_sold
      ON ws.ws_sold_date_sk = ws_sold.d_date_sk
    JOIN web_site webs
      ON ws.ws_web_site_sk = webs.web_site_sk
    WHERE ds_sold.d_date >= DATE '2001-01-01'
      AND ds_sold.d_date <  DATE '2002-01-01'
      AND p.p_response_target = 1
      AND webs.web_mkt_desc LIKE '%market%'
      AND s.s_division_id = 1
      AND i.inv_quantity_on_hand > 0
      AND cs.cs_order_number NOT IN (SELECT ws_order_number FROM web_sales)
),
agg1 AS (
    SELECT
        w_warehouse_name,
        p_promo_name,
        year,
        order_size,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        SUM(cs_net_paid) AS sum_cs_net_paid,
        SUM(ws_net_paid) AS sum_ws_net_paid,
        SUM(inv_qty) AS total_inventory_qty
    FROM base
    GROUP BY w_warehouse_name, p_promo_name, year, order_size
)
SELECT
    w_warehouse_name,
    p_promo_name,
    year,
    order_size,
    order_cnt,
    sum_cs_net_paid,
    sum_ws_net_paid,
    total_inventory_qty,
    (sum_cs_net_paid + sum_ws_net_paid) / NULLIF(order_cnt, 0) AS avg_total_net_paid
FROM agg1
ORDER BY avg_total_net_paid DESC
LIMIT 100
