WITH sales_2001 AS (
    SELECT
        c.cc_state,
        i.i_category,
        d.d_year,
        cd.cd_gender,
        s.ss_net_paid,
        s.ss_ext_discount_amt,
        s.ss_ticket_number
    FROM call_center c
    FULL OUTER JOIN date_dim d ON c.cc_closed_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    JOIN store_sales s ON s.ss_sold_date_sk = d.d_date_sk AND s.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = s.ss_cdemo_sk
    WHERE c.cc_county = 'Jefferson Davis Parish'
      AND d.d_year = 2001
      AND s.ss_ext_discount_amt > 500
),
sales_2002 AS (
    SELECT
        c.cc_state,
        i.i_category,
        d.d_year,
        cd.cd_gender,
        s.ss_net_paid,
        s.ss_ext_discount_amt,
        s.ss_ticket_number
    FROM call_center c
    FULL OUTER JOIN date_dim d ON c.cc_closed_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    JOIN store_sales s ON s.ss_sold_date_sk = d.d_date_sk AND s.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = s.ss_cdemo_sk
    WHERE c.cc_county = 'Jefferson Davis Parish'
      AND d.d_year = 2002
      AND s.ss_ext_discount_amt > 500
),
union_sales AS (
    SELECT * FROM sales_2001
    UNION DISTINCT
    SELECT * FROM sales_2002
),
aggregated AS (
    SELECT
        cc_state,
        i_category,
        d_year,
        cd_gender,
        SUM(ss_net_paid) AS total_net_paid,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
        MIN(ss_ext_discount_amt) AS min_discount,
        MAX(ss_ext_discount_amt) AS max_discount
    FROM union_sales
    GROUP BY cc_state, i_category, d_year, cd_gender
    HAVING SUM(ss_net_paid) > 20000
)
SELECT DISTINCT
    cc_state,
    i_category,
    d_year,
    cd_gender,
    total_net_paid,
    avg_discount,
    distinct_tickets,
    min_discount,
    max_discount
FROM aggregated a
WHERE EXISTS (
    SELECT 1
    FROM customer_demographics cd2
    WHERE cd2.cd_gender = a.cd_gender
      AND cd2.cd_dep_college_count >= 2
)
ORDER BY total_net_paid DESC
LIMIT 100
