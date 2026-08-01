WITH aggregated_returns AS (
    SELECT
        d.d_year,
        i.i_brand_id,
        SUM(sr.sr_net_loss) AS store_loss,
        SUM(cr.cr_net_loss) AS catalog_loss,
        SUM(wr.wr_net_loss) AS web_loss,
        COUNT(*) AS txn_count,
        CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Positive' ELSE 'Negative' END AS loss_indicator
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON i.i_item_sk = ss.ss_item_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp
        ON wp.wp_web_page_sk = wr.wr_web_page_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_current_price > 100
      AND ss.ss_quantity > 5
      AND sr.sr_return_amt > 50
      AND wr.wr_return_amt > 30
    GROUP BY GROUPING SETS (
        (d.d_year, i.i_brand_id),
        (d.d_year),
        ()
    )
)
SELECT
    d_year,
    i_brand_id,
    store_loss,
    catalog_loss,
    web_loss,
    txn_count,
    loss_indicator,
    (store_loss + catalog_loss + web_loss) AS total_loss,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (store_loss + catalog_loss + web_loss) DESC) AS rank_within_year
FROM aggregated_returns
ORDER BY d_year DESC, total_loss DESC
LIMIT 100
