/*
  Goal: Calculate the monthly total net loss for each return reason across catalog and store returns, categorize the loss level, and retain only those reason‑month combinations whose loss exceeds the overall average net loss of all returns.
*/
WITH joined_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        cr.cr_net_loss AS catalog_net_loss,
        sr.sr_net_loss AS store_net_loss,
        inv.inv_quantity_on_hand,
        CASE
            WHEN cr.cr_net_loss + sr.sr_net_loss > 1000 THEN 'High'
            ELSE 'Low'
        END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_customer_sk = c_ret.c_customer_sk
        AND sr.sr_addr_sk = ca_ret.ca_address_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%color%'
      AND cp.cp_catalog_number IN (7, 14)
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    d_year,
    d_month_seq,
    r_reason_desc,
    loss_category,
    SUM(catalog_net_loss) AS total_catalog_loss,
    SUM(store_net_loss)   AS total_store_loss,
    SUM(catalog_net_loss + store_net_loss) AS total_loss,
    COUNT(*) AS transaction_count,
    AVG(SUM(catalog_net_loss + store_net_loss)) OVER (PARTITION BY loss_category) AS avg_loss_by_category
FROM joined_data
GROUP BY d_year, d_month_seq, r_reason_desc, loss_category
HAVING SUM(catalog_net_loss + store_net_loss) > (
    SELECT AVG(cr.cr_net_loss + sr.sr_net_loss)
    FROM catalog_returns cr
    JOIN date_dim dsub ON cr.cr_returned_date_sk = dsub.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = dsub.d_date_sk
)
ORDER BY total_loss DESC
LIMIT 100
