/*
Goal: Identify high‑volume sales groups for the year 2001, limited to Brand#12 items shipped by AIR mode, while excluding any items that also have a web return on the same sale date. The query joins all 11 selected TPC‑DS tables, expands each sale row into two rows via UNNEST of quantity and sales price, aggregates with GROUPING SETS to produce subtotals, filters groups with HAVING, orders by total sales and returns the top 100 rows.
*/
WITH base AS (
    SELECT
        cc.cc_name,
        cp.cp_department,
        i.i_brand,
        i.i_category,
        sm.sm_type,
        d.d_year,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        ws.web_name
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
       AND d.d_date_sk = inv.inv_date_sk
    LEFT JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
       AND d.d_date_sk = wr.wr_returned_date_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND sm.sm_type = 'AIR'
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_item_sk = i.i_item_sk
            AND wr2.wr_returned_date_sk = d.d_date_sk
      )
),
expanded AS (
    SELECT
        cc_name,
        i_brand,
        d_year,
        cs_quantity,
        cs_ext_sales_price,
        cs_net_profit,
        cs_order_number,
        cr_return_quantity,
        cr_return_amount,
        -- expand an array containing quantity and sales price
        t.value AS expanded_value
    FROM base
    CROSS JOIN UNNEST(ARRAY[cs_quantity, cs_ext_sales_price]) AS t(value)
)
SELECT
    cc_name,
    i_brand,
    d_year,
    SUM(cs_quantity)               AS total_quantity,
    SUM(cs_ext_sales_price)        AS total_sales,
    SUM(cs_net_profit)             AS total_profit,
    SUM(cr_return_quantity)        AS total_return_qty,
    SUM(cr_return_amount)          AS total_return_amt,
    COUNT(DISTINCT cs_order_number) AS order_cnt
FROM expanded
GROUP BY GROUPING SETS (
    (cc_name, i_brand, d_year),
    (cc_name, i_brand),
    (cc_name),
    ()
)
HAVING SUM(cs_quantity) > 100
ORDER BY total_sales DESC
LIMIT 100
