WITH
    -- Items that have never been returned (set difference using EXCEPT)
    item_not_returned AS (
        SELECT ss.ss_item_sk
        FROM store_sales ss
        EXCEPT
        SELECT sr.sr_item_sk
        FROM store_returns sr
    ),
    -- Filter items using regex and LIKE, and keep only those not returned
    filtered_items AS (
        SELECT i.i_item_sk,
               i.i_item_desc,
               i.i_current_price
        FROM item i
        WHERE regexp_like(i.i_item_desc, '(?i)premium')
          AND i.i_item_desc LIKE '%Gold%'
          AND i.i_item_sk IN (SELECT ss_item_sk FROM item_not_returned)
    ),
    -- Union of return amounts from store and web returns per reason (UNION = DISTINCT)
    reason_returns_union AS (
        SELECT r.r_reason_desc,
               SUM(sr.sr_return_amt) AS total_return_amt
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        GROUP BY r.r_reason_desc
        UNION
        SELECT r.r_reason_desc,
               SUM(wr.wr_return_amt) AS total_return_amt
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        GROUP BY r.r_reason_desc
    ),
    -- Scalar subquery: average catalog return amount for a reason containing 'color'
    avg_catalog_return AS (
        SELECT AVG(cr.cr_return_amount) AS avg_ret_amt
        FROM catalog_returns cr
        WHERE cr.cr_reason_sk = (
            SELECT r.r_reason_sk
            FROM reason r
            WHERE r.r_reason_desc LIKE '%color%'
            LIMIT 1
        )
    ),
    -- Full outer join between sales and returns (keep unmatched rows from both sides)
    full_join AS (
        SELECT
            COALESCE(ss.ss_ticket_number, sr.sr_ticket_number) AS ticket_number,
            ss.ss_item_sk,
            sr.sr_item_sk,
            ss.ss_net_paid,
            sr.sr_return_amt,
            r.r_reason_desc
        FROM store_sales ss
        FULL OUTER JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE ss.ss_ticket_number IS NOT NULL OR sr.sr_ticket_number IS NOT NULL
    )
SELECT
    fj.ticket_number,
    COALESCE(fi.i_item_desc, 'UNKNOWN') AS item_description,
    fj.r_reason_desc,
    fj.ss_net_paid,
    fj.sr_return_amt,
    CONCAT('Ticket-', CAST(fj.ticket_number AS VARCHAR)) AS ticket_label,
    SUBSTRING(fj.r_reason_desc FROM 1 FOR 20) AS reason_snippet,
    avgc.avg_ret_amt,
    rr.total_return_amt
FROM full_join fj
LEFT JOIN filtered_items fi
    ON fj.ss_item_sk = fi.i_item_sk OR fj.sr_item_sk = fi.i_item_sk
LEFT JOIN avg_catalog_return avgc ON TRUE
LEFT JOIN (
    SELECT r_reason_desc,
           SUM(total_return_amt) AS total_return_amt
    FROM reason_returns_union
    GROUP BY r_reason_desc
) rr ON fj.r_reason_desc = rr.r_reason_desc
WHERE fj.r_reason_desc IS NOT NULL
  AND regexp_like(fj.r_reason_desc, '^Did not like')
ORDER BY fj.ticket_number DESC
LIMIT 100
