WITH joined_data AS (
   SELECT
        s.s_market_id,
        cp.cp_department,
        cr.cr_net_loss,
        sr.sr_net_loss,
        cr.cr_return_amount,
        sr.sr_return_quantity,
        d.d_year,
        ca.ca_state
   FROM catalog_page cp
   JOIN catalog_returns cr
     ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
   JOIN customer_address ca
     ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN store s
     ON s.s_closed_date_sk = d.d_date_sk
   JOIN store_returns sr
     ON sr.sr_store_sk = s.s_store_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
),
agg AS (
   SELECT
        s_market_id,
        cp_department,
        SUM(cr_net_loss) AS cat_net_loss,
        SUM(sr_net_loss) AS store_net_loss,
        COUNT(*) AS cnt_returns
   FROM joined_data
   WHERE d_year = 2001
     AND s_market_id IN (1, 6, 9)
     AND cp_department = 'Electronics'
     AND cr_return_amount > 20
     AND sr_return_quantity >= 1
     AND ca_state = 'CA'
   GROUP BY s_market_id, cp_department
)
SELECT
    s_market_id,
    cp_department,
    cat_net_loss,
    store_net_loss,
    cat_net_loss + store_net_loss AS total_net_loss,
    cnt_returns,
    (cat_net_loss + store_net_loss) / cnt_returns AS avg_net_loss_per_return
FROM agg
WHERE (cat_net_loss + store_net_loss) / cnt_returns > 5
ORDER BY avg_net_loss_per_return DESC
