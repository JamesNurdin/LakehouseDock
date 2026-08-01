SELECT
    d_ss.d_year AS year,
    s.s_store_name AS store_name,
    i.i_category AS category,
    'store' AS source,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS avg_promo_cost,
    lateral_store.total_store_sales_lateral
FROM store_sales ss
JOIN store s ON s.s_store_sk = ss.ss_store_sk
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_ss.d_date_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN date_dim d_web_open ON web.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close ON web.web_close_date_sk = d_web_close.d_date_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_ss.d_date_sk
CROSS JOIN LATERAL (
    SELECT SUM(ss2.ss_net_paid) AS total_store_sales_lateral
    FROM store_sales ss2
    WHERE ss2.ss_store_sk = s.s_store_sk
      AND ss2.ss_sold_date_sk = d_ss.d_date_sk
) AS lateral_store
WHERE d_ss.d_year = 2000
  AND i.i_size = 'large'
  AND s.s_state = 'CA'
GROUP BY d_ss.d_year, s.s_store_name, i.i_category, s.s_store_sk, d_ss.d_date_sk, i.i_item_sk, lateral_store.total_store_sales_lateral

UNION ALL

SELECT
    d_ws.d_year AS year,
    s.s_store_name AS store_name,
    i.i_category AS category,
    'web' AS source,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS avg_promo_cost,
    lateral_store.total_store_sales_lateral
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN date_dim d_web_open ON web.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close ON web.web_close_date_sk = d_web_close.d_date_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_ss.d_date_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_ss.d_date_sk
CROSS JOIN LATERAL (
    SELECT SUM(ss2.ss_net_paid) AS total_store_sales_lateral
    FROM store_sales ss2
    WHERE ss2.ss_store_sk = s.s_store_sk
      AND ss2.ss_sold_date_sk = d_ss.d_date_sk
) AS lateral_store
WHERE d_ws.d_year = 2000
  AND i.i_size = 'large'
  AND s.s_state = 'CA'
GROUP BY d_ws.d_year, s.s_store_name, i.i_category, s.s_store_sk, d_ss.d_date_sk, i.i_item_sk, lateral_store.total_store_sales_lateral

ORDER BY total_sales DESC
LIMIT 100
