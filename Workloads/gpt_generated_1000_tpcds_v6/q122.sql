WITH filtered_items AS (
    SELECT i_item_sk,
           i_category,
           i_class,
           i_rec_start_date
    FROM   item
    WHERE  i_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT return_source,
       i_category,
       i_class,
       total_net_loss
FROM (
    SELECT 'store' AS return_source,
           fi.i_category,
           fi.i_class,
           SUM(sr.sr_net_loss) AS total_net_loss
    FROM   store_returns sr
    JOIN   filtered_items fi
           ON sr.sr_item_sk = fi.i_item_sk
    JOIN   store_sales ss
           ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN   time_dim td
           ON sr.sr_return_time_sk = td.t_time_sk
    GROUP  BY fi.i_category, fi.i_class

    UNION ALL

    SELECT 'catalog' AS return_source,
           fi.i_category,
           fi.i_class,
           SUM(cr.cr_net_loss) AS total_net_loss
    FROM   catalog_returns cr
    JOIN   filtered_items fi
           ON cr.cr_item_sk = fi.i_item_sk
    JOIN   time_dim td
           ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN   call_center cc
           ON cr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP  BY fi.i_category, fi.i_class
) AS combined
ORDER BY total_net_loss DESC
LIMIT 100
