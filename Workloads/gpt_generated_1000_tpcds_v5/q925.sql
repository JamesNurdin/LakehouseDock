WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_month,
        c.c_birth_day,
        i.i_brand,
        i.i_current_price,
        i.i_item_sk,
        inv.inv_quantity_on_hand,
        r.r_reason_desc,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_tax,
        t.t_hour
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    -- additional join to capture the current demographic of the customer (allowed by the schema)
    JOIN customer_demographics cd_cur
        ON c.c_current_cdemo_sk = cd_cur.cd_demo_sk
),
agg AS (
    SELECT
        i_brand,
        r_reason_desc,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity,
        AVG(i_current_price) AS avg_item_price,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers
    FROM joined_data
    WHERE
        c_birth_month IN (1, 2, 3)                     -- filter 1
        AND c_birth_day BETWEEN 10 AND 20            -- filter 2
        AND sr_return_tax > 10.00                    -- filter 3
        AND inv_quantity_on_hand > 0                 -- filter 4
        AND i_current_price BETWEEN 5 AND 100        -- filter 5
        AND t_hour BETWEEN 9 AND 17                  -- filter 6
    GROUP BY GROUPING SETS (
        (i_brand, r_reason_desc),
        (i_brand),
        (r_reason_desc),
        ()
    )
)
SELECT
    i_brand,
    r_reason_desc,
    total_return_amount,
    total_return_quantity,
    avg_item_price,
    distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_return_amount DESC) AS brand_return_rank,
    RANK() OVER (ORDER BY total_return_amount DESC) AS overall_return_rank
FROM agg
ORDER BY total_return_amount DESC, i_brand, r_reason_desc
LIMIT 100
