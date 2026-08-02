WITH filtered_data AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_month,
        c.c_birth_year,
        c.c_current_cdemo_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_ship_cost,
        sr.sr_ticket_number
    FROM customer c
    FULL OUTER JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE (c.c_current_cdemo_sk IN (229409, 290962) OR c.c_current_cdemo_sk IS NULL)
      AND (c.c_birth_month IN (6, 10, 11) OR c.c_birth_month IS NULL)
      AND (c.c_birth_year BETWEEN 1950 AND 1980 OR c.c_birth_year IS NULL)
      AND (sr.sr_return_quantity BETWEEN 10 AND 35 OR sr.sr_return_quantity IS NULL)
      AND (sr.sr_return_ship_cost > 10.00 OR sr.sr_return_ship_cost IS NULL)
      AND (sr.sr_return_amt >= 100.00 OR sr.sr_return_amt IS NULL)
      AND (sr.sr_ticket_number IN (5031864, 5031869, 5031861) OR sr.sr_ticket_number IS NULL)
)
SELECT
    category_type,
    category,
    c_birth_month,
    num_returns,
    total_return_amt,
    avg_return_amt,
    min_return_amt,
    max_return_amt,
    total_quantity,
    avg_quantity,
    min_quantity,
    max_quantity
FROM (
    SELECT
        'Amount' AS category_type,
        CASE WHEN fd.sr_return_amt >= 500 THEN 'Very High' ELSE 'High' END AS category,
        fd.c_birth_month,
        COUNT(*) AS num_returns,
        SUM(fd.sr_return_amt) AS total_return_amt,
        AVG(fd.sr_return_amt) AS avg_return_amt,
        MIN(fd.sr_return_amt) AS min_return_amt,
        MAX(fd.sr_return_amt) AS max_return_amt,
        SUM(fd.sr_return_quantity) AS total_quantity,
        AVG(fd.sr_return_quantity) AS avg_quantity,
        MIN(fd.sr_return_quantity) AS min_quantity,
        MAX(fd.sr_return_quantity) AS max_quantity
    FROM filtered_data fd
    GROUP BY
        fd.c_birth_month,
        CASE WHEN fd.sr_return_amt >= 500 THEN 'Very High' ELSE 'High' END
    UNION ALL
    SELECT
        'Quantity' AS category_type,
        CASE WHEN fd.sr_return_quantity > 20 THEN 'LargeQty' ELSE 'SmallQty' END AS category,
        fd.c_birth_month,
        COUNT(*) AS num_returns,
        SUM(fd.sr_return_amt) AS total_return_amt,
        AVG(fd.sr_return_amt) AS avg_return_amt,
        MIN(fd.sr_return_amt) AS min_return_amt,
        MAX(fd.sr_return_amt) AS max_return_amt,
        SUM(fd.sr_return_quantity) AS total_quantity,
        AVG(fd.sr_return_quantity) AS avg_quantity,
        MIN(fd.sr_return_quantity) AS min_quantity,
        MAX(fd.sr_return_quantity) AS max_quantity
    FROM filtered_data fd
    GROUP BY
        fd.c_birth_month,
        CASE WHEN fd.sr_return_quantity > 20 THEN 'LargeQty' ELSE 'SmallQty' END
) combined
ORDER BY category_type, category, c_birth_month
LIMIT 100
