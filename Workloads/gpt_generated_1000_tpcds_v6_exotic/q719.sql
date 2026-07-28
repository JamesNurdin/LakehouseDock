WITH recent_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2022
)
SELECT reason_desc,
       total_net_loss,
       source
FROM (
    SELECT r.r_reason_desc AS reason_desc,
           SUM(sr.sr_net_loss) AS total_net_loss,
           'store' AS source
    FROM store_returns sr
    JOIN recent_dates rd ON sr.sr_returned_date_sk = rd.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_reason_sk = sr.sr_reason_sk
            AND sr2.sr_net_loss > 500
      )
    GROUP BY r.r_reason_desc
    HAVING SUM(sr.sr_net_loss) > (
        SELECT AVG(net_loss)
        FROM (
            SELECT SUM(sr3.sr_net_loss) AS net_loss
            FROM store_returns sr3
            JOIN recent_dates rd3 ON sr3.sr_returned_date_sk = rd3.d_date_sk
            WHERE sr3.sr_net_loss > 0
            UNION ALL
            SELECT SUM(cr3.cr_net_loss) AS net_loss
            FROM catalog_returns cr3
            JOIN recent_dates rd3c ON cr3.cr_returned_date_sk = rd3c.d_date_sk
            WHERE cr3.cr_net_loss > 0
        ) t
    )

    UNION ALL

    SELECT r.r_reason_desc AS reason_desc,
           SUM(cr.cr_net_loss) AS total_net_loss,
           'catalog' AS source
    FROM catalog_returns cr
    JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_reason_sk = cr.cr_reason_sk
            AND cr2.cr_net_loss > 500
      )
    GROUP BY r.r_reason_desc
    HAVING SUM(cr.cr_net_loss) > (
        SELECT AVG(net_loss)
        FROM (
            SELECT SUM(sr3.sr_net_loss) AS net_loss
            FROM store_returns sr3
            JOIN recent_dates rd3 ON sr3.sr_returned_date_sk = rd3.d_date_sk
            WHERE sr3.sr_net_loss > 0
            UNION ALL
            SELECT SUM(cr3.cr_net_loss) AS net_loss
            FROM catalog_returns cr3
            JOIN recent_dates rd3c ON cr3.cr_returned_date_sk = rd3c.d_date_sk
            WHERE cr3.cr_net_loss > 0
        ) t
    )
) combined
ORDER BY total_net_loss DESC
LIMIT 100
