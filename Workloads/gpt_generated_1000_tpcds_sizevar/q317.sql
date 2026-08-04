/* Goal: Identify the top‑10 selling items (by net sales) per category for the year 2002 that also had any return amount, using a sampled inventory view and ranking via a window function. */
WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_quarter_seq,
        d.d_current_year,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cp.cp_catalog_page_id,
        i.i_item_sk,
        i.i_category_id,
        i.i_brand_id,
        i.i_formulation,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        wp.wp_type,
        ws.web_manager
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN (
        SELECT * FROM tpcds.inventory TABLESAMPLE BERNOULLI (10)
    ) inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
       AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_quarter_seq IN (5, 15)
      AND i.i_category_id = 5
      AND i.i_brand_id BETWEEN 2002000 AND 3000000
      AND cs.cs_quantity > 1
      AND cs.cs_sales_price > 100
      AND ws.web_manager = 'Dwight Aaron'
      AND wp.wp_type = 'typeA'
),
sales_rank AS (
    SELECT
        i_item_sk,
        i_category_id,
        d_year,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY i_category_id, d_year ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM base
    GROUP BY i_item_sk, i_category_id, d_year
),
returns_agg AS (
    SELECT
        i_item_sk,
        SUM(sr_return_amt) AS total_returns
    FROM base
    GROUP BY i_item_sk
)
SELECT intersected_item_sk
FROM (
    SELECT sr.i_item_sk AS intersected_item_sk
    FROM sales_rank sr
    WHERE sr.sales_rank <= 10
    INTERSECT
    SELECT ra.i_item_sk
    FROM returns_agg ra
    WHERE ra.total_returns > 0
) t
LIMIT 100
