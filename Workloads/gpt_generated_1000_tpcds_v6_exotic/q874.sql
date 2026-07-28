WITH base_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cp.cp_catalog_page_number,
        w.w_warehouse_name,
        r.r_reason_desc,
        i.i_brand,
        i.i_item_id,
        p.p_channel_catalog,
        d.d_year,
        hd.hd_income_band_sk,
        ca.ca_state,
        sr.sr_return_amt,
        s.s_store_name,
        wp.wp_url,
        ws.web_tax_percentage
    FROM tpcds.catalog_returns cr
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN tpcds.date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND p.p_channel_catalog = 'N'
      AND ws.web_tax_percentage > 0.05
)
SELECT *
FROM (
    SELECT
        s_store_name AS entity,
        d_year AS year,
        SUM(sr_return_amt) AS total_return_amount,
        'store' AS entity_type
    FROM base_data
    GROUP BY s_store_name, d_year

    UNION ALL

    SELECT
        CAST(cp_catalog_page_number AS VARCHAR) AS entity,
        d_year AS year,
        SUM(cr_return_amount) AS total_return_amount,
        'catalog_page' AS entity_type
    FROM base_data
    GROUP BY cp_catalog_page_number, d_year
) AS combined
LIMIT 100
