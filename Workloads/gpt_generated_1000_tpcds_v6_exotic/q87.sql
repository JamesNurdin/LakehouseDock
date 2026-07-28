-- Goal: Analyze net sales and inventory for US web‑site customers in the year 2000 during business hours, broken down by product brand, customer gender, household income band and web‑site name.
-- The query joins all ten selected TPC‑DS tables, applies several realistic filters, uses a DISTINCT sub‑query on inventory, aggregates key measures and returns the top 100 rows.
WITH ws_base AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_coupon_amt,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_ext_tax,
        ws.ws_net_paid_inc_ship,
        ws.ws_ext_ship_cost
    FROM web_sales ws
    WHERE ws.ws_net_paid_inc_ship > 1000
),
distinct_inventory AS (
    SELECT DISTINCT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 500
)
SELECT
    d.d_year,
    i.i_brand,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ws_site.web_name,
    COUNT(DISTINCT ws_base.ws_order_number) AS unique_orders,
    SUM(ws_base.ws_net_paid)                AS total_net_paid,
    AVG(ws_base.ws_coupon_amt)              AS avg_coupon_amount,
    MIN(ws_base.ws_ext_sales_price)         AS min_ext_sales_price,
    MAX(distinct_inventory.inv_quantity_on_hand) AS max_inventory_quantity
FROM ws_base
JOIN date_dim d
  ON ws_base.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ws_base.ws_sold_time_sk = t.t_time_sk
JOIN item i
  ON ws_base.ws_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON ws_base.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ws_base.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp
  ON ws_base.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site
  ON ws_base.ws_web_site_sk = ws_site.web_site_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
 AND sr.sr_returned_date_sk = d.d_date_sk
JOIN distinct_inventory
  ON distinct_inventory.inv_item_sk = i.i_item_sk
 AND distinct_inventory.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2000
  AND t.t_hour BETWEEN 6 AND 15
  AND i.i_current_price > 50
  AND ws_site.web_country = 'United States'
GROUP BY
    d.d_year,
    i.i_brand,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ws_site.web_name
ORDER BY total_net_paid DESC
LIMIT 100
