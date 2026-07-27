WITH filtered_returns AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_cdemo_sk,
        sr.sr_store_sk,
        sr.sr_fee,
        sr.sr_return_amt,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_quantity,
        sr.sr_ticket_number,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        i.i_rec_end_date,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_dep_college_count
    FROM store_returns sr
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_current_price BETWEEN 10 AND 50
      AND i.i_rec_end_date > DATE '2000-01-01'
      AND sr.sr_fee > 20.00
      AND cd.cd_dep_college_count >= 2
),
agg_returns AS (
    SELECT
        fr.i_brand,
        fr.i_category,
        fr.cd_education_status,
        COUNT(DISTINCT fr.sr_ticket_number) AS distinct_tickets,
        SUM(fr.sr_return_amt) AS total_return_amt,
        AVG(fr.sr_return_amt_inc_tax) AS avg_return_inc_tax,
        MIN(fr.sr_return_quantity) AS min_quantity,
        MAX(fr.sr_return_quantity) AS max_quantity
    FROM filtered_returns fr
    GROUP BY fr.i_brand, fr.i_category, fr.cd_education_status
)
SELECT
    a.i_brand,
    a.i_category,
    a.cd_education_status,
    a.distinct_tickets,
    a.total_return_amt,
    a.avg_return_inc_tax,
    a.min_quantity,
    a.max_quantity,
    SUM(a.total_return_amt) OVER (
        PARTITION BY a.i_brand
        ORDER BY a.total_return_amt DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_brand_return
FROM agg_returns a
ORDER BY a.total_return_amt DESC
LIMIT 100
