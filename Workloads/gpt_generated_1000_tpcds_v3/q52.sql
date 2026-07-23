WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        w.w_state,
        hd.hd_buy_potential,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        AVG(cs.cs_ext_ship_cost) AS avg_ship_cost,
        MIN(cs.cs_net_paid) AS min_net_paid,
        MAX(cs.cs_net_paid) AS max_net_paid
    FROM
        catalog_sales cs
        INNER JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        INNER JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        INNER JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        INNER JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN store_sales ss
            ON ss.ss_sold_date_sk = d.d_date_sk
            AND ss.ss_item_sk = i.i_item_sk
            AND ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = i.i_item_sk
            AND sr.sr_returned_date_sk = d.d_date_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = i.i_item_sk
            AND cr.cr_returned_date_sk = d.d_date_sk
            AND cr.cr_warehouse_sk = w.w_warehouse_sk
            AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE
        d.d_year = 1998
        AND d.d_month_seq BETWEEN 1200 AND 1210
        AND hd.hd_income_band_sk IN (13, 15)
        AND hd.hd_buy_potential = '5001-10000'
        AND w.w_state = 'CA'
        AND cs.cs_ext_ship_cost > 1000
        AND cs.cs_ext_wholesale_cost < 2000
        AND EXISTS (
            SELECT 1
            FROM reason r
            WHERE r.r_reason_sk = cr.cr_reason_sk
              AND r.r_reason_desc = 'Damaged'
        )
        AND EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_ticket_number = ss.ss_ticket_number
              AND sr2.sr_return_quantity > 0
        )
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        w.w_state,
        hd.hd_buy_potential
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_brand,
    w_state,
    hd_buy_potential,
    order_cnt,
    total_net_paid,
    total_ship_cost,
    total_store_return_amt,
    total_catalog_net_loss,
    avg_ship_cost,
    min_net_paid,
    max_net_paid
FROM sales_agg
ORDER BY d_year DESC, d_month_seq, total_net_paid DESC
LIMIT 100
