WITH returns_agg AS (
    SELECT
        s.s_city,
        s.s_state,
        s.s_manager,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_manager LIKE '%John%'
      AND s.s_city LIKE 'A%'
      AND regexp_like(s.s_manager, '^[A-M].*')
    GROUP BY s.s_city, s.s_state, s.s_manager
)
SELECT
    CONCAT(r.s_city, ', ', r.s_state) AS location,
    regexp_extract(r.s_manager, '^([^ ]+)', 1) AS manager_first_name,
    r.total_net_loss,
    r.total_return_amount
FROM returns_agg r
ORDER BY r.total_net_loss DESC
LIMIT 20
