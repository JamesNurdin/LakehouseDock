WITH ws_filtered AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_ext_list_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND ws.ws_ext_list_price > 15000
)
SELECT
    d.d_year,
    ca.ca_state,
    hd.hd_buy_potential,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT ws_filtered.ws_order_number) AS distinct_web_orders,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    MAX(ws_filtered.ws_ext_list_price) AS max_web_price,
    MIN(sr.sr_return_amt) AS min_store_return_amt
FROM date_dim d
JOIN customer c ON c.c_first_sales_date_sk = d.d_date_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN web_site wsite ON wsite.web_open_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN ws_filtered ON ws_filtered.ws_sold_date_sk = d.d_date_sk
JOIN web_returns wr ON wr.wr_order_number = ws_filtered.ws_order_number
WHERE ca.ca_state = 'CA'
  AND hd.hd_buy_potential = '>10000'
  AND ib.ib_lower_bound >= 50000
  AND ss.ss_ticket_number NOT IN (
        SELECT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_return_quantity > 0
    )
  AND hd.hd_vehicle_count = (
        SELECT MAX(hd3.hd_vehicle_count)
        FROM household_demographics hd3
    )
GROUP BY d.d_year, ca.ca_state, hd.hd_buy_potential
ORDER BY total_store_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
