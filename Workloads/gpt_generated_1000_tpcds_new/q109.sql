WITH base AS (
    SELECT
        i.i_item_sk               AS item_sk,
        i.i_item_id               AS item_id,
        i.i_brand                 AS brand,
        sm.sm_ship_mode_id        AS ship_mode_id,
        sm.sm_carrier             AS carrier,
        d.d_year                  AS year,
        SUM(ss.ss_ext_sales_price)          AS total_sales,
        SUM(ss.ss_net_profit)                AS total_profit,
        SUM(sr.sr_return_amt)                AS total_store_return,
        SUM(cr.cr_return_amount)             AS total_catalog_return,
        SUM(inv.inv_quantity_on_hand)        AS total_inventory_on_hand,
        COUNT(DISTINCT ss.ss_ticket_number)  AS sales_transactions,
        COUNT(DISTINCT sr.sr_ticket_number)  AS store_return_transactions,
        COUNT(DISTINCT cr.cr_order_number)   AS catalog_return_transactions
    FROM store_sales ss
    JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i              ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND i.i_brand = 'Brand#23'
      AND sm.sm_carrier = 'USPS'
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        d.d_year
),
stats AS (
    SELECT AVG(total_sales - total_store_return - total_catalog_return) AS avg_net_sales
    FROM base
)
SELECT
    b.item_sk,
    b.item_id,
    b.brand,
    b.ship_mode_id,
    b.carrier,
    b.year,
    b.total_sales,
    b.total_profit,
    b.total_store_return,
    b.total_catalog_return,
    b.total_inventory_on_hand,
    b.sales_transactions,
    b.store_return_transactions,
    b.catalog_return_transactions,
    (b.total_sales - b.total_store_return - b.total_catalog_return) AS net_sales_after_returns,
    (b.total_profit / NULLIF(b.total_sales, 0)) * 100 AS profit_margin_pct
FROM base b
CROSS JOIN stats s
WHERE (b.total_sales - b.total_store_return - b.total_catalog_return) > s.avg_net_sales
ORDER BY net_sales_after_returns DESC
LIMIT 100
