WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(sr.sr_return_amt) AS returns_total,
    (SUM(ss.ss_ext_sales_price) + SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(sr.sr_return_amt)) AS total_profit,
    inv.total_on_hand,
    (
        SELECT AVG(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
    ) AS avg_store_sales,
    ROW_NUMBER() OVER (
        PARTITION BY s.s_store_id
        ORDER BY (SUM(ss.ss_ext_sales_price) + SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(sr.sr_return_amt)) DESC
    ) AS profit_rank
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_bill_customer_sk = c.c_customer_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory_agg inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = i.i_item_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_customer_sk = c.c_customer_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE s.s_state = 'CA'
  AND i.i_color IN ('sienna', 'pink')
  AND c.c_birth_year BETWEEN 1950 AND 1965
  AND ib.ib_upper_bound > 60000
  AND cs.cs_sold_date_sk BETWEEN 2450830 AND 2450840
GROUP BY
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    inv.total_on_hand,
    s.s_store_sk
ORDER BY total_profit DESC, profit_rank ASC
LIMIT 100
