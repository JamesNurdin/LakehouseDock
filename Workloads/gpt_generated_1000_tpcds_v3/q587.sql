SELECT
    cc.cc_call_center_id,
    CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
    regexp_extract(c.c_email_address, '@([^.]*)\\.com', 1) AS email_domain,
    CASE
        WHEN regexp_extract(c.c_email_address, '@([^.]*)\\.com', 1) = 'example' THEN 'Example'
        ELSE 'Other'
    END AS email_domain_group,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_quantity,
    CASE
        WHEN SUM(ss.ss_net_profit) > (SELECT avg(ss2.ss_net_profit) FROM store_sales ss2) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM store_sales ss
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_customer_sk = c.c_customer_sk
WHERE cc.cc_zip LIKE '7%'
  AND regexp_like(c.c_email_address, '@[a-z]+\\.com$')
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
          AND regexp_like(CAST(cr2.cr_order_number AS VARCHAR), '^26344[0-9]$')
    )
GROUP BY
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    regexp_extract(c.c_email_address, '@([^.]*)\\.com', 1),
    CASE
        WHEN regexp_extract(c.c_email_address, '@([^.]*)\\.com', 1) = 'example' THEN 'Example'
        ELSE 'Other'
    END
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
