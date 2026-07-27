WITH base AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_returned_date_sk,
        d.d_date,
        d.d_year,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        cd_ret.cd_gender AS returning_gender,
        cd_ref.cd_credit_rating AS refunded_credit_rating
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN customer_demographics cd_ret
        ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN customer_demographics cd_ref
        ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    WHERE d.d_year = 2001
      AND inv.inv_warehouse_sk IN (13, 16, 10)
      AND cd_ret.cd_gender = 'M'
      AND cd_ref.cd_credit_rating = 'A'
),
agg AS (
    SELECT
        d_year,
        inv_warehouse_sk,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM base
    GROUP BY d_year, inv_warehouse_sk
),
ranked AS (
    SELECT
        d_year,
        inv_warehouse_sk,
        total_return_amt,
        avg_quantity_on_hand,
        RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS warehouse_return_rank
    FROM agg
)
SELECT
    d_year,
    inv_warehouse_sk,
    total_return_amt,
    avg_quantity_on_hand,
    warehouse_return_rank
FROM ranked
ORDER BY d_year, warehouse_return_rank
LIMIT 100
