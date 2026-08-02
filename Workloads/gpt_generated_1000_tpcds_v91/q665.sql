WITH base AS (
    SELECT
        d.d_year,
        i.i_brand,
        s.s_state,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 1999 AND 2001
        AND d.d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
        AND i.i_brand = 'Brand#45'
        AND c.c_birth_country IN ('SWITZERLAND', 'RWANDA')
        AND hd.hd_vehicle_count >= 2
        AND s.s_state = 'TX'
        AND t.t_hour BETWEEN 9 AND 17
        AND wr.wr_refunded_customer_sk IN (3146224, 2503811)
),
agg AS (
    SELECT
        d_year,
        i_brand,
        s_state,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_return_quantity) AS total_return_qty,
        AVG(wr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_count
    FROM base
    GROUP BY CUBE (d_year, i_brand, s_state)
)
SELECT
    d_year,
    i_brand,
    s_state,
    total_return_amount,
    total_return_qty,
    avg_net_loss,
    return_count,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM agg
ORDER BY return_amount_rank, d_year, i_brand, s_state
LIMIT 100
