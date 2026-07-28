WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    d.d_year,
    i.i_brand,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(ws.ws_net_paid) AS total_web_sales,
    AVG(inv_agg.total_qty) AS avg_inventory_qty,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
FROM date_dim d
-- Catalog Returns and its dimensions
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON i.i_item_sk = cr.cr_item_sk
JOIN customer_address ca_ref ON ca_ref.ca_address_sk = cr.cr_refunded_addr_sk
JOIN customer_address ca_ret ON ca_ret.ca_address_sk = cr.cr_returning_addr_sk
JOIN customer_demographics cd_ref ON cd_ref.cd_demo_sk = cr.cr_refunded_cdemo_sk
JOIN customer_demographics cd_ret ON cd_ret.cd_demo_sk = cr.cr_returning_cdemo_sk
JOIN household_demographics hd_ref ON hd_ref.hd_demo_sk = cr.cr_refunded_hdemo_sk
JOIN household_demographics hd_ret ON hd_ret.hd_demo_sk = cr.cr_returning_hdemo_sk
JOIN income_band ib_ref ON ib_ref.ib_income_band_sk = hd_ref.hd_income_band_sk
JOIN income_band ib_ret ON ib_ret.ib_income_band_sk = hd_ret.hd_income_band_sk
-- Store Returns and its dimensions
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_item_sk = i.i_item_sk
JOIN customer_address ca_sr ON ca_sr.ca_address_sk = sr.sr_addr_sk
JOIN customer_demographics cd_sr ON cd_sr.cd_demo_sk = sr.sr_cdemo_sk
JOIN household_demographics hd_sr ON hd_sr.hd_demo_sk = sr.sr_hdemo_sk
JOIN income_band ib_sr ON ib_sr.ib_income_band_sk = hd_sr.hd_income_band_sk
-- Web Sales and its dimensions
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_item_sk = i.i_item_sk
JOIN customer_address ca_ws_bill ON ca_ws_bill.ca_address_sk = ws.ws_bill_addr_sk
JOIN customer_address ca_ws_ship ON ca_ws_ship.ca_address_sk = ws.ws_ship_addr_sk
JOIN customer_demographics cd_ws_bill ON cd_ws_bill.cd_demo_sk = ws.ws_bill_cdemo_sk
JOIN customer_demographics cd_ws_ship ON cd_ws_ship.cd_demo_sk = ws.ws_ship_cdemo_sk
JOIN household_demographics hd_ws_bill ON hd_ws_bill.hd_demo_sk = ws.ws_bill_hdemo_sk
JOIN household_demographics hd_ws_ship ON hd_ws_ship.hd_demo_sk = ws.ws_ship_hdemo_sk
JOIN income_band ib_ws_bill ON ib_ws_bill.ib_income_band_sk = hd_ws_bill.hd_income_band_sk
JOIN income_band ib_ws_ship ON ib_ws_ship.ib_income_band_sk = hd_ws_ship.hd_income_band_sk
JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
JOIN promotion p ON p.p_promo_sk = ws.ws_promo_sk
-- Pre‑aggregated inventory
JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
    AND inv_agg.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2000
    AND i.i_brand_id = 5
    AND ib_ref.ib_upper_bound > 50000
    AND we.web_tax_percentage < 0.07
    AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY
    d.d_year,
    i.i_brand
HAVING
    SUM(cr.cr_return_amount) > 1000
ORDER BY
    total_web_sales DESC
LIMIT 100
