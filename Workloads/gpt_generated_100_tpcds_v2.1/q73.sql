WITH distinct_cc AS (
    SELECT DISTINCT cc_call_center_sk, cc_state
    FROM call_center
    WHERE cc_state = 'CA'
),
inv_agg AS (
    SELECT inv.inv_date_sk, inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    GROUP BY inv.inv_date_sk, inv.inv_item_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state AS store_state,
    dc.cc_state AS call_center_state,
    i.i_brand,
    cd.cd_gender,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(inv_agg.total_inventory_qty) AS total_inventory_quantity,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    MIN(d.d_date) AS min_sale_date,
    MAX(d.d_date) AS max_sale_date
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_item_sk = i.i_item_sk
    AND cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN distinct_cc dc
    ON cr.cr_call_center_sk = dc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_item_sk = i.i_item_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN inv_agg
    ON inv_agg.inv_date_sk = d.d_date_sk
    AND inv_agg.inv_item_sk = i.i_item_sk
WHERE
    d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND cd.cd_gender = 'M'
    AND cr.cr_return_amount > 1000.00
    AND s.s_state = 'TX'
    AND cp.cp_type = 'A'
    AND wp.wp_type = 'HOME'
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_state,
    dc.cc_state,
    i.i_brand,
    cd.cd_gender
ORDER BY
    total_sales_amount DESC,
    d.d_month_seq ASC
LIMIT 100
