WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        s.s_store_name,
        s.s_state,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_item_sk = i.i_item_sk
),
agg AS (
    SELECT
        b.s_store_name,
        b.s_state,
        b.d_year,
        b.d_month_seq,
        b.i_brand,
        b.i_category,
        SUM(b.ss_ext_sales_price)                         AS total_sales,
        SUM(b.sr_return_amt)                               AS total_return_amount,
        SUM(cr.cr_return_amount)                           AS total_catalog_return_amount,
        COUNT(DISTINCT b.ss_ticket_number)                 AS transaction_count,
        AVG(b.i_current_price)                             AS avg_item_price,
        MIN(b.d_date)                                      AS first_sale_date,
        MAX(b.d_date)                                      AS last_sale_date
    FROM base b
    JOIN catalog_returns cr
        ON cr.cr_item_sk = b.i_item_sk
    JOIN date_dim dcr
        ON cr.cr_returned_date_sk = dcr.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE EXISTS (
            SELECT 1
            FROM ship_mode sm
            WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
              AND sm.sm_carrier = 'USPS'
        )
      AND b.d_year = 2002
      AND b.i_brand = 'barcallyese'
      AND b.s_state = 'CA'
      AND cc.cc_tax_percentage > 5.00
      AND b.inv_quantity_on_hand > 0
      AND dcr.d_year = 2002
    GROUP BY
        b.s_store_name,
        b.s_state,
        b.d_year,
        b.d_month_seq,
        b.i_brand,
        b.i_category
)
SELECT
    a.*, 
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank
FROM agg a
ORDER BY a.d_year, sales_rank
LIMIT 100
