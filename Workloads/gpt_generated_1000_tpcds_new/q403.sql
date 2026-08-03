WITH avg_nl AS (
    SELECT avg(sr_net_loss) AS avg_loss
    FROM store_returns
)

SELECT
    i.i_category,
    CASE WHEN sr.sr_net_loss > 1000 THEN 'High Loss' ELSE 'Low Loss' END AS loss_category,
    sr.sr_return_quantity,
    lt.total_return_amt,
    sr.sr_net_loss,
    avg_nl.avg_loss
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
CROSS JOIN LATERAL (
    SELECT sum(sr2.sr_return_amt) AS total_return_amt
    FROM store_returns sr2
    WHERE sr2.sr_item_sk = sr.sr_item_sk
      AND sr2.sr_returned_date_sk = sr.sr_returned_date_sk
) lt
CROSS JOIN avg_nl
WHERE c.c_preferred_cust_flag = 'Y'
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = sr.sr_customer_sk
          AND sr3.sr_returned_date_sk = sr.sr_returned_date_sk
          AND sr3.sr_return_amt > sr.sr_return_amt
  )
  AND sr.sr_net_loss > (SELECT avg_loss FROM avg_nl)

UNION ALL

SELECT
    i.i_category,
    CASE WHEN sr.sr_net_loss > 1000 THEN 'High Loss' ELSE 'Low Loss' END AS loss_category,
    sr.sr_return_quantity,
    lt.total_return_amt,
    sr.sr_net_loss,
    avg_nl.avg_loss
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
CROSS JOIN LATERAL (
    SELECT sum(sr2.sr_return_amt) AS total_return_amt
    FROM store_returns sr2
    WHERE sr2.sr_item_sk = sr.sr_item_sk
      AND sr2.sr_returned_date_sk = sr.sr_returned_date_sk
) lt
CROSS JOIN avg_nl
WHERE c.c_preferred_cust_flag = 'N'
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = sr.sr_customer_sk
          AND sr3.sr_returned_date_sk = sr.sr_returned_date_sk
          AND sr3.sr_return_amt > sr.sr_return_amt
  )
  AND sr.sr_net_loss > (SELECT avg_loss FROM avg_nl)
