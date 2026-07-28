WITH base AS (
    SELECT
        d.d_year,
        s.s_state,
        i_cr.i_brand,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_returns cr ON d.d_date_sk = cr.cr_returned_date_sk
    JOIN tpcds.store_returns sr ON d.d_date_sk = sr.sr_returned_date_sk
    JOIN tpcds.web_returns wr ON d.d_date_sk = wr.wr_returned_date_sk
    JOIN tpcds.inventory inv ON d.d_date_sk = inv.inv_date_sk
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.item i_cr ON cr.cr_item_sk = i_cr.i_item_sk
    JOIN tpcds.item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
    JOIN tpcds.item i_wr ON wr.wr_item_sk = i_wr.i_item_sk
    JOIN tpcds.item i_inv ON inv.inv_item_sk = i_inv.i_item_sk
    JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN tpcds.customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN tpcds.customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i_cr.i_brand = 'barcallyable'
      AND inv.inv_quantity_on_hand > 500
      AND (cr.cr_net_loss > 0 OR sr.sr_net_loss > 0 OR wr.wr_net_loss > 0)
),
aggregated AS (
    SELECT
        d_year,
        s_state,
        i_brand,
        COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0) + COALESCE(wr_net_loss, 0) AS total_net_loss
    FROM base
)
SELECT
    d_year,
    s_state,
    i_brand,
    SUM(total_net_loss) AS sum_net_loss,
    COUNT(*) AS cnt_rows,
    AVG(total_net_loss) AS avg_net_loss
FROM aggregated
GROUP BY GROUPING SETS (
    (d_year, s_state, i_brand),
    (d_year, s_state),
    (d_year),
    ()
)
HAVING SUM(total_net_loss) > 1000
ORDER BY sum_net_loss DESC
LIMIT 100
