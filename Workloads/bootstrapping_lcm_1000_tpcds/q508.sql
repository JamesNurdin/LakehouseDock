WITH store_ret_agg AS (
    SELECT
        sr.sr_store_sk,
        d_ret.d_date_sk,
        d_ret.d_year,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    GROUP BY sr.sr_store_sk, d_ret.d_date_sk, d_ret.d_year
),
web_ret_agg AS (
    SELECT
        d_ret.d_date_sk,
        d_ret.d_year,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    GROUP BY d_ret.d_date_sk, d_ret.d_year
),
promotion_period AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        d_start.d_date AS start_date,
        d_end.d_date   AS end_date,
        p.p_cost
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
)
SELECT
    s.s_store_id,
    s.s_city,
    d.d_year,
    pp.p_promo_name,
    SUM(COALESCE(sr.total_store_net_loss, 0)) AS total_store_net_loss,
    SUM(COALESCE(wr.total_web_net_loss, 0))   AS total_web_net_loss,
    SUM(COALESCE(sr.total_store_net_loss, 0)) + SUM(COALESCE(wr.total_web_net_loss, 0)) AS total_net_loss,
    SUM(COALESCE(sr.store_return_cnt, 0)) AS store_return_cnt,
    SUM(COALESCE(wr.web_return_cnt, 0))   AS web_return_cnt,
    MIN(d_closed.d_date) AS store_closed_date,
    AVG(pp.p_cost) AS avg_promo_cost
FROM store s
JOIN store_ret_agg sr
    ON s.s_store_sk = sr.sr_store_sk
JOIN date_dim d
    ON sr.d_date_sk = d.d_date_sk
LEFT JOIN web_ret_agg wr
    ON d.d_date_sk = wr.d_date_sk
JOIN promotion_period pp
    ON d.d_date >= pp.start_date
   AND d.d_date <= pp.end_date
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'NY'
GROUP BY s.s_store_id, s.s_city, d.d_year, pp.p_promo_name
HAVING (SUM(COALESCE(sr.total_store_net_loss, 0)) + SUM(COALESCE(wr.total_web_net_loss, 0))) > 0
ORDER BY total_net_loss DESC
LIMIT 100
