WITH avg_tax AS (
    SELECT AVG(sr_return_tax) AS val
    FROM store_returns
    WHERE sr_store_sk = 325
)
SELECT manager_id,
       item_class,
       total_return_amt,
       return_cnt
FROM (
    -- Sub‑query 1: inner join with a class filter and tax > average tax
    SELECT
        i.i_manager_id      AS manager_id,
        i.i_class           AS item_class,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(sr.sr_ticket_number) AS return_cnt
    FROM item i
    JOIN store_returns sr
        ON i.i_item_sk = sr.sr_item_sk
    WHERE i.i_class = 'sports-apparel'
      AND sr.sr_return_tax > (SELECT val FROM avg_tax)
    GROUP BY i.i_manager_id, i.i_class

    UNION ALL

    -- Sub‑query 2: full outer join keeping unmatched rows, with a different class filter
    SELECT
        i.i_manager_id      AS manager_id,
        i.i_class           AS item_class,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amt,
        COUNT(sr.sr_ticket_number) AS return_cnt
    FROM item i
    FULL OUTER JOIN store_returns sr
        ON i.i_item_sk = sr.sr_item_sk
    WHERE i.i_class = 'swimwear'
      AND (sr.sr_return_tax <= (SELECT val FROM avg_tax) OR sr.sr_return_tax IS NULL)
    GROUP BY i.i_manager_id, i.i_class
) combined
ORDER BY total_return_amt DESC
LIMIT 100
