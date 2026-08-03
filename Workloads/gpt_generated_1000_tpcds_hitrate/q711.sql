/* Goal: Analyse catalog return amounts by store (including stores without returns) and by returning household demographic, showing running totals, and comparing each row to the total return amount for the same household demographic. The query combines two filtered result sets with UNION ALL, uses a FULL OUTER JOIN to keep unmatched store/return rows, filters returns via an IN sub‑query, adds a correlated scalar sub‑query, and computes a running sum with a window function. */
WITH store_dates AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_county,
        s.s_closed_date_sk,
        d.d_date_sk,
        d.d_date,
        d.d_year
    FROM store s
    LEFT JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
),
return_dates AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_returning_hdemo_sk,
        d.d_date,
        d.d_year
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_refunded_hdemo_sk IN (
        SELECT hd_demo_sk
        FROM household_demographics
        WHERE hd_income_band_sk = 5
    )
),
full_join AS (
    SELECT
        sd.s_store_sk,
        sd.s_store_id,
        sd.s_county,
        rd.cr_returned_date_sk,
        rd.cr_return_amount,
        rd.cr_return_quantity,
        rd.cr_returning_hdemo_sk,
        COALESCE(sd.d_date, rd.d_date)   AS event_date,
        COALESCE(sd.d_year, rd.d_year)   AS event_year
    FROM store_dates sd
    FULL OUTER JOIN return_dates rd
        ON sd.s_closed_date_sk = rd.cr_returned_date_sk
),
sub1 AS (
    /* Rows that have a store (may or may not have a matching return) */
    SELECT
        fj.s_store_id,
        fj.s_county,
        fj.event_date,
        fj.cr_return_amount,
        (
            SELECT SUM(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_returning_hdemo_sk = fj.cr_returning_hdemo_sk
        ) AS total_return_amount_by_hdemo,
        SUM(fj.cr_return_amount) OVER (
            PARTITION BY fj.s_store_id
            ORDER BY fj.event_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_return_amount
    FROM full_join fj
    WHERE fj.s_store_sk IS NOT NULL
),
sub2 AS (
    /* Rows that have a return but no matching store */
    SELECT
        CAST(NULL AS VARCHAR)                AS s_store_id,
        CAST(NULL AS VARCHAR)                AS s_county,
        fj.event_date,
        fj.cr_return_amount,
        (
            SELECT SUM(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_returning_hdemo_sk = fj.cr_returning_hdemo_sk
        ) AS total_return_amount_by_hdemo,
        SUM(fj.cr_return_amount) OVER (
            PARTITION BY fj.event_date
            ORDER BY fj.event_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_return_amount
    FROM full_join fj
    WHERE fj.s_store_sk IS NULL
      AND fj.cr_return_amount IS NOT NULL
)
SELECT
    s_store_id,
    s_county,
    event_date,
    cr_return_amount,
    total_return_amount_by_hdemo,
    running_return_amount
FROM (
    SELECT * FROM sub1
    UNION ALL
    SELECT * FROM sub2
) combined
ORDER BY s_store_id, event_date
