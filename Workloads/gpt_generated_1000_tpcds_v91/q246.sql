/*
Goal: Analyze total sales, store returns, catalog returns, and inventory by item brand and year, including website coverage. The query joins all nine selected TPC‑DS tables using the allowed join rules, reuses the time_dim table under three aliases, performs a FULL OUTER JOIN on inventory, aggregates the data, and adds window functions for total sales per year and ranking.
*/
WITH raw_data AS (
    SELECT
        i.i_brand_id,
        d_sales.d_year,
        ss.ss_ext_sales_price,
        sr.sr_return_amt,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        ws.web_site_id
    FROM tpcds.store_sales AS ss
    INNER JOIN tpcds.date_dim AS d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    INNER JOIN tpcds.time_dim AS t_sold
        ON ss.ss_sold_time_sk = t_sold.t_time_sk
    INNER JOIN tpcds.item AS i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN tpcds.store_returns AS sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    INNER JOIN tpcds.date_dim AS d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    INNER JOIN tpcds.time_dim AS t_return
        ON sr.sr_return_time_sk = t_return.t_time_sk
    INNER JOIN tpcds.catalog_returns AS cr
        ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN tpcds.date_dim AS d_cr_return
        ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    INNER JOIN tpcds.time_dim AS t_cr_return
        ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
    INNER JOIN tpcds.catalog_page AS cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN tpcds.date_dim AS d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    INNER JOIN tpcds.date_dim AS d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    FULL OUTER JOIN tpcds.inventory AS inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d_sales.d_date_sk
    INNER JOIN tpcds.web_site AS ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
    INNER JOIN tpcds.date_dim AS d_web_close
        ON ws.web_close_date_sk = d_web_close.d_date_sk
    WHERE d_sales.d_year = 2001
),
brand_agg AS (
    SELECT
        i_brand_id AS brand_id,
        d_year AS sales_year,
        SUM(ss_ext_sales_price) AS total_sales_amount,
        SUM(sr_return_amt) AS total_store_return_amount,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
        COUNT(DISTINCT web_site_id) AS distinct_websites
    FROM raw_data
    GROUP BY i_brand_id, d_year
)
SELECT
    brand_id,
    sales_year,
    total_sales_amount,
    total_store_return_amount,
    total_catalog_return_amount,
    total_inventory_on_hand,
    distinct_websites,
    SUM(total_sales_amount) OVER (PARTITION BY sales_year) AS total_sales_all_brands,
    RANK() OVER (PARTITION BY sales_year ORDER BY total_sales_amount DESC) AS sales_rank
FROM brand_agg
ORDER BY sales_year, total_sales_amount DESC
LIMIT 100
