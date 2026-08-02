WITH filtered_cc AS (
    SELECT *
    FROM call_center
    WHERE cc_state = 'CA'
      AND cc_call_center_sk IN (
          SELECT cs_call_center_sk
          FROM catalog_sales
          WHERE cs_quantity > 10
      )
)
SELECT
    d_cs_sold.d_year,
    d_cs_sold.d_month_seq,
    fc.cc_name,
    s.s_store_name,
    cp.cp_catalog_page_number,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    MIN(d_cs_sold.d_date) AS min_sold_date,
    MAX(d_ws_ship.d_date) AS max_ship_date
FROM filtered_cc fc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = fc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cs_sold
    ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_cs_ship
    ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_cs_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cs_ship.d_date_sk
JOIN date_dim d_cc_closed
    ON fc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE
    d_cs_sold.d_year = 2001
    AND inv.inv_quantity_on_hand > 500
    AND cp.cp_catalog_number = 5
GROUP BY
    d_cs_sold.d_year,
    d_cs_sold.d_month_seq,
    fc.cc_name,
    s.s_store_name,
    cp.cp_catalog_page_number
ORDER BY
    total_profit DESC,
    d_cs_sold.d_year,
    d_cs_sold.d_month_seq
LIMIT 100
