WITH sub1 AS (
   SELECT
        d_store.d_fy_year                     AS fiscal_year,
        r_store.r_reason_desc                 AS reason,
        SUM(sr.sr_return_amt)                 AS store_return_amount,
        SUM(sr.sr_net_loss)                   AS store_net_loss,
        SUM(cr.cr_return_amount)              AS catalog_return_amount,
        SUM(cr.cr_net_loss)                   AS catalog_net_loss,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS inventory_qty,
        CASE 
            WHEN SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) > 10000 THEN 'High Loss'
            ELSE 'Low Loss'
        END                                   AS loss_category
   FROM store_returns sr
   JOIN date_dim d_store
     ON sr.sr_returned_date_sk = d_store.d_date_sk
   JOIN customer_demographics cd_ret
     ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
   JOIN reason r_store
     ON sr.sr_reason_sk = r_store.r_reason_sk
   LEFT JOIN inventory inv
     ON inv.inv_date_sk = d_store.d_date_sk
        AND inv.inv_item_sk = sr.sr_item_sk
   JOIN catalog_returns cr
     ON cr.cr_returned_date_sk = d_store.d_date_sk
   JOIN date_dim d_catalog
     ON cr.cr_returned_date_sk = d_catalog.d_date_sk
   JOIN customer_demographics cd_refund
     ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
   JOIN customer_demographics cd_returning
     ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
   JOIN reason r_catalog
     ON cr.cr_reason_sk = r_catalog.r_reason_sk
   JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d_cc_open
     ON cc.cc_open_date_sk = d_cc_open.d_date_sk
   LEFT JOIN date_dim d_cc_close
     ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
   JOIN web_site ws
     ON ws.web_open_date_sk = d_cc_open.d_date_sk
   LEFT JOIN date_dim d_web_close
     ON ws.web_close_date_sk = d_web_close.d_date_sk
   GROUP BY d_store.d_fy_year, r_store.r_reason_desc
   HAVING SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) > 5000
),
sub2 AS (
   SELECT
        d_store2.d_fy_year                     AS fiscal_year,
        r_store2.r_reason_desc                  AS reason,
        SUM(sr2.sr_return_amt)                  AS store_return_amount,
        SUM(cr2.cr_return_amount)               AS catalog_return_amount,
        CASE 
            WHEN COUNT(*) > 100 THEN 'Frequent'
            ELSE 'Infrequent'
        END                                      AS activity_level
   FROM store_returns sr2
   JOIN date_dim d_store2
     ON sr2.sr_returned_date_sk = d_store2.d_date_sk
   JOIN reason r_store2
     ON sr2.sr_reason_sk = r_store2.r_reason_sk
   JOIN catalog_returns cr2
     ON cr2.cr_returned_date_sk = d_store2.d_date_sk
   GROUP BY d_store2.d_fy_year, r_store2.r_reason_desc
   HAVING SUM(cr2.cr_return_amount) > 1000
)
SELECT
    fiscal_year,
    reason,
    store_return_amount,
    catalog_return_amount,
    loss_category
FROM sub1
UNION ALL
SELECT
    fiscal_year,
    reason,
    store_return_amount,
    catalog_return_amount,
    activity_level AS loss_category
FROM sub2
ORDER BY fiscal_year DESC, reason
LIMIT 100
