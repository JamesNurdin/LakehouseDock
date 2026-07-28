WITH sr AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_hdemo_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
),
agg AS (
    SELECT
        s.s_store_name,
        i.i_brand,
        p.p_promo_name,
        d_sr.d_year,
        SUM(sr.sr_return_amt)        AS total_return_amount,
        SUM(sr.sr_net_loss)          AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns
    FROM sr
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk                     -- join 1
    JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk                         -- join 2
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk                                   -- join 3
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk                                 -- join 4
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk                               -- join 5
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk                                -- join 6
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk                    -- join 7
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk                            -- join 8
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk                                      -- join 9
    JOIN date_dim d_p_start
        ON p.p_start_date_sk = d_p_start.d_date_sk                        -- join 10
    JOIN date_dim d_p_end
        ON p.p_end_date_sk = d_p_end.d_date_sk                            -- join 11
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_p_end.d_date_sk                       -- join 12
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_date_sk = d_sr.d_date_sk                        -- join 13 (uses rule on wr.wr_returned_date_sk)
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk                         -- join 14
    JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk                         -- join 15
    JOIN household_demographics hd_wr
        ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk                      -- join 16
    WHERE d_sr.d_year BETWEEN 1918 AND 1919
      AND s.s_country = 'United States'
    GROUP BY ROLLUP (s.s_store_name, i.i_brand, p.p_promo_name, d_sr.d_year)
)
SELECT
    a.s_store_name,
    a.i_brand,
    a.p_promo_name,
    a.d_year,
    a.total_return_amount,
    a.total_net_loss,
    a.distinct_returns,
    SUM(a.total_return_amount) OVER (
        PARTITION BY a.s_store_name
        ORDER BY a.d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amount
FROM agg a
ORDER BY a.total_return_amount DESC
LIMIT 100
