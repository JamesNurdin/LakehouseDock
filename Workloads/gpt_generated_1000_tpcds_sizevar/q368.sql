/*
Goal: Produce a year‑level summary of sales and returns, categorizing households by buying potential.
The query joins all 15 TPC‑DS tables using the allowed join keys, re‑uses date_dim and customer_demographics
under different aliases, pre‑aggregates inventory in a CTE, combines two SELECTs with UNION DISTINCT, uses a
CASE expression, groups, orders and limits the result.
*/
WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    year,
    buy_potential_category,
    total_sales,
    total_quantity,
    total_inventory_qty
FROM (
    -- 1️⃣ Web sales side (year = 2001)
    SELECT
        d_sale.d_year AS year,
        CASE WHEN hd_bill.hd_buy_potential = '0-500' THEN 'Low' ELSE 'High' END AS buy_potential_category,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(inv_agg.total_qty) AS total_inventory_qty
    FROM web_sales ws
    JOIN date_dim d_sale ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN time_dim t_sale ON ws.ws_sold_time_sk = t_sale.t_time_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inv_agg ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
                 AND inv_agg.inv_date_sk = d_sale.d_date_sk
    LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d_sale.d_date_sk
    WHERE d_sale.d_year = 2001
    GROUP BY d_sale.d_year,
             CASE WHEN hd_bill.hd_buy_potential = '0-500' THEN 'Low' ELSE 'High' END

    UNION DISTINCT

    -- 2️⃣ Store returns side (year = 2002)
    SELECT
        d_ret.d_year AS year,
        CASE WHEN hd_ret.hd_buy_potential = '0-500' THEN 'Low' ELSE 'High' END AS buy_potential_category,
        SUM(sr.sr_return_amt) AS total_sales,
        SUM(sr.sr_return_quantity) AS total_quantity,
        CAST(0 AS BIGINT) AS total_inventory_qty
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN income_band ib2 ON hd_ret.hd_income_band_sk = ib2.ib_income_band_sk
    LEFT JOIN catalog_page cp2 ON cp2.cp_end_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2002
    GROUP BY d_ret.d_year,
             CASE WHEN hd_ret.hd_buy_potential = '0-500' THEN 'Low' ELSE 'High' END
) AS combined
ORDER BY year DESC,
         total_sales DESC
LIMIT 100
