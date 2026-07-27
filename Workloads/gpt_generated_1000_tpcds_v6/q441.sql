/*
Goal: Rank stores by total net loss per fiscal year for high‑value returns, filtered by date, quantity, amount, item start date and store state.
*/
WITH base AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        d.d_year,
        d.d_date,
        i.i_category,
        i.i_rec_start_date,
        s.s_store_name,
        s.s_state
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE
        d.d_date BETWEEN DATE '1900-01-01' AND DATE '1900-01-31'          -- filter 1
        AND cr.cr_return_quantity > 1                                   -- filter 2
        AND cr.cr_return_amount > 10.00                                 -- filter 3
        AND i.i_rec_start_date >= DATE '1999-01-01'                     -- filter 4
        AND s.s_state = 'CA'                                            -- filter 5
),
agg AS (
    SELECT
        d_year,
        s_store_name,
        i_category,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss
    FROM base
    GROUP BY d_year, s_store_name, i_category
)
SELECT
    d_year,
    s_store_name,
    i_category,
    total_return_amount,
    total_net_loss,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY d_year DESC, net_loss_rank ASC, total_return_amount DESC
LIMIT 100
