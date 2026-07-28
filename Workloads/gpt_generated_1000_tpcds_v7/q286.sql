/*
   Goal: Compare the total net paid amount per customer from catalog sales and web sales for customers whose transactions are linked to
         call centers or web pages that were active in the year 2001. The query unions the two sales sources, aggregates per customer
         and source, orders by the highest total net paid, and returns the top 100 rows.
*/
SELECT
    t.customer_id,
    SUM(t.net_paid) AS total_net_paid,
    t.source
FROM (
    /* Catalog sales side */
    SELECT
        c.c_customer_id AS customer_id,
        cs.cs_net_paid AS net_paid,
        'catalog' AS source
    FROM catalog_sales cs
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'

    UNION ALL

    /* Web sales side */
    SELECT
        c.c_customer_id AS customer_id,
        ws.ws_net_paid AS net_paid,
        'web' AS source
    FROM web_sales ws
    INNER JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
) t
GROUP BY
    t.customer_id,
    t.source
ORDER BY
    total_net_paid DESC
LIMIT 100
