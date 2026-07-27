WITH agg AS (
    SELECT
        s.s_store_name,
        s.s_state,
        d.d_year,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE EXISTS (
        SELECT 1 FROM web_site ws
        WHERE ws.web_open_date_sk = d.d_date_sk
          AND ws.web_state = s.s_state
    )
      AND s.s_state = 'CA'
      AND d.d_year BETWEEN 2000 AND 2002
      AND cd.cd_gender = 'F'
      AND r.r_reason_desc = 'Damaged'
    GROUP BY s.s_store_name, s.s_state, d.d_year
)
SELECT
    s_store_name,
    s_state,
    d_year,
    total_return_amt,
    total_net_loss,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS revenue_rank
FROM agg
ORDER BY d_year ASC, revenue_rank ASC
LIMIT 100
