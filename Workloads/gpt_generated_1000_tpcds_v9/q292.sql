WITH base_data AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        i.i_units,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ca.ca_city,
        cc.cc_name,
        cc.cc_tax_percentage,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        ss.ss_sales_price,
        ss.ss_net_profit,
        sr.sr_return_amt,
        sr.sr_net_loss,
        cr.cr_return_amount,
        cr.cr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wp.wp_type AS web_page_type
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON w.w_warehouse_sk = inv.inv_warehouse_sk
        AND w.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
),
agg_data AS (
    SELECT
        d_year,
        i_category,
        i_brand,
        i_item_sk,
        SUM(cr_return_amount) AS total_catalog_return,
        SUM(sr_return_amt) AS total_store_return,
        SUM(wr_return_amt) AS total_web_return,
        SUM(cr_net_loss) AS total_catalog_net_loss,
        SUM(sr_net_loss) AS total_store_net_loss,
        SUM(wr_net_loss) AS total_web_net_loss,
        SUM(ss_sales_price) AS total_sales_price,
        SUM(ss_net_profit) AS total_net_profit,
        MAX(cc_tax_percentage) AS cc_tax_percentage
    FROM base_data
    WHERE d_year BETWEEN 2000 AND 2002
      AND i_current_price > 10
      AND cc_tax_percentage <= 0.10
      AND i_units = 'Lb'
    GROUP BY ROLLUP (d_year, i_category, i_brand, i_item_sk)
)
SELECT
    d_year,
    i_category,
    i_brand,
    i_item_sk,
    total_catalog_return,
    total_store_return,
    total_web_return,
    (total_catalog_return + total_store_return + total_web_return) AS total_return_amount,
    total_catalog_net_loss,
    total_store_net_loss,
    total_web_net_loss,
    total_sales_price,
    total_net_profit,
    DENSE_RANK() OVER (PARTITION BY d_year ORDER BY (total_catalog_return + total_store_return + total_web_return) DESC) AS return_rank_year,
    (SELECT SUM(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_item_sk = agg_data.i_item_sk) AS total_catalog_return_all_years
FROM agg_data
WHERE (total_catalog_return + total_store_return + total_web_return) > 5000
ORDER BY d_year, total_return_amount DESC
LIMIT 100
