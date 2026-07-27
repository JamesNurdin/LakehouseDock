WITH base AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        d.d_year,
        d.d_qoy,
        c.c_first_name,
        c.c_last_name,
        r.r_reason_desc,
        i.inv_quantity_on_hand,
        wp.wp_max_ad_count,
        wp.wp_image_count,
        ROW_NUMBER() OVER (PARTITION BY sr.sr_customer_sk ORDER BY d.d_date DESC) AS rn
    FROM store_returns AS sr
    JOIN date_dim AS d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer AS c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason AS r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory AS i ON d.d_date_sk = i.inv_date_sk
    JOIN web_page AS wp ON c.c_customer_sk = wp.wp_customer_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 2
      AND wp.wp_max_ad_count >= 2
      AND sr.sr_return_amt > 100
      AND r.r_reason_desc LIKE '%Damaged%'
),
filtered AS (
    SELECT *
    FROM base
    WHERE rn = 1
)
SELECT
    f.d_year AS year,
    f.d_qoy AS quarter,
    f.r_reason_desc AS reason,
    SUM(f.sr_return_amt) AS total_return_amount,
    AVG(f.inv_quantity_on_hand) AS avg_quantity_on_hand,
    COUNT(DISTINCT f.sr_customer_sk) AS distinct_customers,
    (
        SELECT AVG(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_returned_date_sk IN (
            SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_year = 2001
        )
    ) AS overall_avg_return_amount
FROM filtered f
GROUP BY f.d_year, f.d_qoy, f.r_reason_desc
HAVING SUM(f.sr_return_amt) > 500
ORDER BY total_return_amount DESC
LIMIT 10
