WITH max_year AS (
    SELECT MAX(d_year) AS yr FROM date_dim
)
SELECT
    s.s_store_id,
    i.i_category,
    d_store.d_year,
    SUM(cs.cs_net_paid) AS total_catalog_net,
    SUM(ws.ws_net_paid) AS total_web_net,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(wr.wr_net_loss) AS total_return_loss,
    CASE
        WHEN SUM(cs.cs_net_paid) > SUM(ws.ws_net_paid) THEN 'Catalog'
        ELSE 'Web'
    END AS higher_sales_source,
    (SELECT COUNT(*) FROM web_site wsit WHERE wsit.web_city = s.s_city) AS site_count_same_city,
    (SELECT yr FROM max_year) AS dataset_max_year
FROM store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_store.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_store.d_date_sk
JOIN item i ON i.i_item_sk = cs.cs_item_sk AND i.i_item_sk = ws.ws_item_sk
JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk AND w.w_warehouse_sk = ws.ws_warehouse_sk
JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
JOIN customer_address ca_bill ON ca_bill.ca_address_sk = cs.cs_bill_addr_sk
JOIN customer_address ca_ship ON ca_ship.ca_address_sk = cs.cs_ship_addr_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_date_sk = d_store.d_date_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
JOIN reason r ON r.r_reason_sk = wr.wr_reason_sk
JOIN web_site wsit ON wsit.web_site_sk = ws.ws_web_site_sk
JOIN time_dim t_cs ON t_cs.t_time_sk = cs.cs_sold_time_sk
JOIN time_dim t_ws ON t_ws.t_time_sk = ws.ws_sold_time_sk
WHERE d_store.d_year BETWEEN 1998 AND 2000
  AND s.s_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND cc.cc_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND r.r_reason_desc LIKE '%defect%'
  AND wsit.web_city = s.s_city
GROUP BY s.s_store_id, i.i_category, d_store.d_year, s.s_city
HAVING SUM(cs.cs_net_paid) > (
    SELECT AVG(total_catalog_net) FROM (
        SELECT SUM(cs2.cs_net_paid) AS total_catalog_net
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year BETWEEN 1998 AND 2000
    ) t
)
ORDER BY total_catalog_net DESC
LIMIT 100
