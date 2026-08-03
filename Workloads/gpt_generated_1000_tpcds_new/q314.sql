WITH ss_agg AS (
        SELECT ss.ss_ticket_number AS order_key,
               SUM(ss.ss_net_paid) AS total_paid
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE d.d_year = 2001
        GROUP BY ss.ss_ticket_number
        HAVING SUM(ss.ss_net_paid) > 1000
    ),
    cs_agg AS (
        SELECT cs.cs_order_number AS order_key,
               SUM(cs.cs_net_paid) AS total_paid
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE d.d_year = 2001
          AND cp.cp_type = 'F'
        GROUP BY cs.cs_order_number
        HAVING SUM(cs.cs_net_paid) > 1000
    ),
    returns_agg AS (
        SELECT sr.sr_ticket_number AS order_key
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    )
SELECT k.order_key,
       ss.total_paid,
       (
           SELECT COUNT(*)
           FROM store_returns sr2
           WHERE sr2.sr_ticket_number = k.order_key
       ) AS return_cnt
FROM (
        SELECT order_key FROM ss_agg
        INTERSECT
        SELECT order_key FROM cs_agg
        EXCEPT
        SELECT order_key FROM returns_agg
) AS k
JOIN ss_agg ss ON ss.order_key = k.order_key
ORDER BY ss.total_paid DESC
LIMIT 100
