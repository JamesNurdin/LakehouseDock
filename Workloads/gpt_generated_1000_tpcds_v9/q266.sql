WITH catalog_fact AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cr.cr_return_amount
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
), agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        cp.cp_department,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(cf.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cf.cr_return_amount) AS total_catalog_returns,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
        ib.ib_upper_bound AS income_upper_bound,
        COUNT(DISTINCT url_part) AS distinct_url_parts,
        (SUM(cf.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price)) AS total_sales
    FROM catalog_fact cf
    JOIN date_dim d
        ON cf.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cf.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON cf.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cf.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON cf.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cf.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cf.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cf.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
       AND ss.ss_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(url_part)
    LEFT JOIN income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    WHERE d.d_year = 1999
      AND i.i_brand = 'Brand#45'
      AND p.p_channel_email = 'N'
      AND EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_item_sk = i.i_item_sk
            AND sr2.sr_return_quantity > 0
      )
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        cp.cp_department,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_upper_bound
)
SELECT
    d_year,
    d_month_seq,
    i_item_id,
    i_product_name,
    cp_department,
    cd_gender,
    total_catalog_sales,
    total_store_sales,
    total_web_sales,
    total_catalog_returns,
    total_store_return_qty,
    total_inventory_on_hand,
    income_upper_bound,
    distinct_url_parts,
    total_sales,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY d_year, sales_rank
LIMIT 100
