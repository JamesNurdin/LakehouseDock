-- Goal: Identify yearly sales performance, distinct customers and tickets, and tax metrics across the full data set, 
-- applying selective filters, anti‑join exclusion, scalar sub‑query reference, and combining two filtered aggregates via UNION.
SELECT *
FROM (
    SELECT
        d.d_year,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        AVG(cc.cc_tax_percentage) AS avg_tax_pct,
        MIN(ss.ss_net_paid) AS min_net_paid,
        MAX(ss.ss_net_paid) AS max_net_paid,
        (SELECT AVG(cc_inner.cc_tax_percentage)
         FROM call_center cc_inner
         WHERE cc_inner.cc_division = 1) AS overall_avg_tax_div1
    FROM
        store_sales ss
        FULL OUTER JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
        INNER JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        INNER JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        INNER JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        INNER JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        INNER JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        INNER JOIN catalog_returns cr
            ON cr.cr_reason_sk = r.r_reason_sk
        INNER JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        INNER JOIN web_page wp
            ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        cc.cc_division IN (1, 3)
        AND cc.cc_tax_percentage > 0.05
        AND c.c_birth_country = 'VANUATU'
        AND d.d_year = 2001
        AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_ticket_number = ss.ss_ticket_number
              AND sr2.sr_return_quantity > 5
        )
    GROUP BY
        d.d_year
    HAVING
        SUM(ss.ss_net_paid_inc_tax) > 10000

    UNION DISTINCT

    SELECT
        d.d_year,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        AVG(cc.cc_tax_percentage) AS avg_tax_pct,
        MIN(ss.ss_net_paid) AS min_net_paid,
        MAX(ss.ss_net_paid) AS max_net_paid,
        (SELECT AVG(cc_inner.cc_tax_percentage)
         FROM call_center cc_inner
         WHERE cc_inner.cc_division = 1) AS overall_avg_tax_div1
    FROM
        store_sales ss
        FULL OUTER JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
        INNER JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        INNER JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        INNER JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        INNER JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        INNER JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        INNER JOIN catalog_returns cr
            ON cr.cr_reason_sk = r.r_reason_sk
        INNER JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        INNER JOIN web_page wp
            ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        cc.cc_division = 2
        AND cc.cc_tax_percentage BETWEEN 0.04 AND 0.06
        AND c.c_birth_country = 'BAHAMAS'
        AND d.d_year = 2002
        AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_returned_date_sk = d.d_date_sk
              AND cr2.cr_return_amount > 5000
        )
    GROUP BY
        d.d_year
    HAVING
        SUM(ss.ss_net_paid_inc_tax) > 5000
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
