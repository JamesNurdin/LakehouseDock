WITH
    sampled_inventory AS (
        SELECT inv_date_sk, inv_quantity_on_hand
        FROM inventory TABLESAMPLE BERNOULLI (10)
        WHERE inv_quantity_on_hand > 0
    ),
    returned AS (
        SELECT wr.wr_returned_date_sk AS date_sk,
               wr.wr_return_amt,
               lc.return_size
        FROM web_returns wr
        CROSS JOIN LATERAL (
            SELECT CASE WHEN wr.wr_return_amt > 500 THEN 'Big' ELSE 'Small' END AS return_size
        ) lc
        WHERE wr.wr_return_amt > 100
    ),
    full_join AS (
        SELECT
            COALESCE(r.date_sk, i.inv_date_sk) AS date_sk,
            r.wr_return_amt,
            i.inv_quantity_on_hand
        FROM returned r
        FULL OUTER JOIN sampled_inventory i
            ON r.date_sk = i.inv_date_sk
    ),
    intersect_dates AS (
        SELECT date_sk
        FROM returned
        INTERSECT
        SELECT inv_date_sk AS date_sk
        FROM sampled_inventory
    ),
    except_dates AS (
        SELECT date_sk
        FROM returned
        EXCEPT
        SELECT inv_date_sk AS date_sk
        FROM sampled_inventory
    )
SELECT
    d.date_sk,
    d.src_type,
    CASE WHEN d.date_sk % 2 = 0 THEN 'Even' ELSE 'Odd' END AS parity
FROM (
    SELECT date_sk, 'INTERSECT' AS src_type FROM intersect_dates
    UNION ALL
    SELECT date_sk, 'EXCEPT'    AS src_type FROM except_dates
) d
ORDER BY d.date_sk
LIMIT 100
