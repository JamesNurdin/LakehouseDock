WITH wr_agg AS (
    SELECT d_wr.d_date_sk AS date_sk,
           SUM(wr.wr_return_amt) AS total_web_return_amt
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE d_wr.d_year = 2001
    GROUP BY d_wr.d_date_sk
),
store_agg AS (
    SELECT
        sr.sr_ticket_number,
        d_sr.d_date,
        t_sr.t_shift,
        s.s_store_name,
        cp.cp_description,
        p.p_promo_name,
        SUM(sr.sr_return_quantity) AS total_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        SUM(p.p_cost) AS total_promo_cost
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sr.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d_sr.d_date_sk
    LEFT JOIN wr_agg wa ON wa.date_sk = d_sr.d_date_sk
    WHERE d_sr.d_year = 2001
      AND t_sr.t_shift = 'first'
      AND s.s_state = 'CA'
      AND p.p_channel_demo = 'N'
      AND cp.cp_type = 'A'
      AND (wa.total_web_return_amt IS NULL OR wa.total_web_return_amt > 1000)
    GROUP BY
        sr.sr_ticket_number,
        d_sr.d_date,
        t_sr.t_shift,
        s.s_store_name,
        cp.cp_description,
        p.p_promo_name
)
SELECT
    sr_ticket_number,
    d_date,
    t_shift,
    s_store_name,
    cp_description,
    p_promo_name,
    total_qty,
    total_return_amt,
    avg_return_tax,
    total_promo_cost,
    ROW_NUMBER() OVER (ORDER BY d_date DESC) AS rn
FROM store_agg
ORDER BY rn
LIMIT 100
