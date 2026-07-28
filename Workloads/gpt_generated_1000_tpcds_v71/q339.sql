WITH joined_data AS (
    SELECT
        d.d_year,
        s.s_store_name,
        i.i_category,
        i.i_brand,
        w.w_state,
        sm.sm_type,
        hd.hd_income_band_sk,
        ca.ca_state AS customer_state,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cr.cr_net_loss,
        sr.sr_net_loss AS store_return_loss,
        wr.wr_net_loss AS web_return_loss,
        inv.inv_quantity_on_hand,
        ws.web_name,
        wp.wp_type,
        i.i_item_sk
    FROM date_dim d
    JOIN store s               ON s.s_closed_date_sk      = d.d_date_sk
    JOIN store_returns sr      ON sr.sr_returned_date_sk  = d.d_date_sk
    JOIN catalog_returns cr    ON cr.cr_returned_date_sk  = d.d_date_sk
    JOIN catalog_sales cs      ON cs.cs_sold_date_sk      = d.d_date_sk
    JOIN web_returns wr        ON wr.wr_returned_date_sk  = d.d_date_sk
    JOIN web_page wp           ON wp.wp_creation_date_sk  = d.d_date_sk
    JOIN web_site ws           ON ws.web_open_date_sk     = d.d_date_sk
    JOIN inventory inv         ON inv.inv_date_sk         = d.d_date_sk
    JOIN item i                ON cs.cs_item_sk           = i.i_item_sk
    JOIN ship_mode sm          ON cs.cs_ship_mode_sk      = sm.sm_ship_mode_sk
    JOIN warehouse w           ON cs.cs_warehouse_sk      = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca   ON cs.cs_bill_addr_sk      = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND w.w_state = 'CA'
)
SELECT
    d_year,
    s_store_name,
    i_category,
    SUM(cs_net_paid)                         AS total_net_paid,
    SUM(cs_ext_sales_price)                  AS total_sales,
    SUM(inv_quantity_on_hand)                AS total_inventory,
    COUNT(DISTINCT i_item_sk)                AS distinct_items_sold,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(cs_net_paid) DESC) AS sales_rank,
    CASE
        WHEN SUM(cs_net_paid) > 1000000 THEN 'High'
        WHEN SUM(cs_net_paid) > 500000  THEN 'Medium'
        ELSE 'Low'
    END                                      AS sales_level,
    (SELECT MAX(i_current_price)
       FROM item
      WHERE i_category = joined_data.i_category) AS max_price_in_category
FROM joined_data
GROUP BY d_year, s_store_name, i_category
HAVING SUM(cs_net_paid) > 200000
ORDER BY d_year DESC, sales_rank
LIMIT 100
