WITH base AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_return_quantity,
        cd.cd_gender,
        cd.cd_education_status,
        d.d_year,
        i.inv_quantity_on_hand,
        wp.wp_link_count
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN inventory i
      ON i.inv_date_sk = d.d_date_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
      AND i.inv_quantity_on_hand > 500
),
categories AS (
    SELECT 'All' AS cat UNION ALL SELECT 'Special' AS cat
)
SELECT
    d_year,
    cd_gender,
    qty_range,
    cat,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(sr_fee) AS avg_fee,
    COUNT(*) AS cnt_records,
    COUNT(DISTINCT sr_ticket_number) AS distinct_tickets,
    MIN(inv_quantity_on_hand) AS min_qty_on_hand,
    MAX(inv_quantity_on_hand) AS max_qty_on_hand
FROM (
    SELECT
        b.d_year,
        b.cd_gender,
        CASE WHEN b.inv_quantity_on_hand > 800 THEN 'High' ELSE 'Low' END AS qty_range,
        b.sr_return_amt,
        b.sr_fee,
        b.sr_ticket_number,
        b.inv_quantity_on_hand
    FROM base b
) a
CROSS JOIN categories cat
GROUP BY GROUPING SETS (
    (d_year, cd_gender, qty_range, cat),
    (d_year, cd_gender, cat),
    (d_year, cat),
    (cat)
)
ORDER BY total_return_amt DESC
LIMIT 100
