/*
  Goal: Identify promotional campaigns that generated high distinct return activity and net loss for stores in California during 2001, while filtering on several business criteria. The query joins all five selected tables, performs layered aggregations, computes distinct aggregates, removes promotions with low net loss via EXCEPT, and excludes promotions matching a pattern using an anti‑semi‑join. Results are ordered by net loss and limited to 100 rows.
*/
WITH joined AS (
    SELECT
        dr.d_year,
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_channel_email,
        r.r_reason_desc,
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_net_loss,
        ws.web_site_id,
        ws.web_state
    FROM store_returns sr
    JOIN date_dim dr
        ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN promotion p
        ON p.p_start_date_sk = dr.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = dr.d_date_sk
    WHERE dr.d_year = 2001
      AND p.p_channel_email = 'N'
      AND r.r_reason_desc LIKE '%work%'
      AND sr.sr_return_tax > 10
      AND ws.web_state = 'CA'
      AND p.p_cost > 50
),
agg1 AS (
    SELECT
        d_year,
        p_promo_name,
        r_reason_desc,
        COUNT(DISTINCT sr_ticket_number) AS distinct_ticket_cnt,
        SUM(DISTINCT sr_return_amt) AS sum_distinct_return_amt,
        COUNT(DISTINCT web_site_id) AS distinct_web_site_cnt,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_net_loss) AS total_net_loss
    FROM joined
    GROUP BY d_year, p_promo_name, r_reason_desc
),
high AS (
    SELECT *
    FROM agg1
    WHERE distinct_ticket_cnt > 5
      AND sum_distinct_return_amt > 100
      AND total_return_tax > 200
),
low AS (
    SELECT p_promo_name
    FROM agg1
    WHERE total_net_loss < 0
),
promo_excluded AS (
    SELECT p_promo_name
    FROM high
    EXCEPT
    SELECT p_promo_name
    FROM low
),
final AS (
    SELECT
        h.d_year,
        h.p_promo_name,
        h.r_reason_desc,
        h.distinct_ticket_cnt,
        h.sum_distinct_return_amt,
        h.distinct_web_site_cnt,
        h.total_return_tax,
        h.total_net_loss
    FROM high h
    WHERE h.p_promo_name NOT IN (
        SELECT p.p_promo_name
        FROM promotion p
        WHERE p.p_promo_name LIKE 'Discount%'
    )
      AND h.p_promo_name IN (SELECT p_promo_name FROM promo_excluded)
)
SELECT
    d_year,
    p_promo_name,
    r_reason_desc,
    distinct_ticket_cnt,
    sum_distinct_return_amt,
    distinct_web_site_cnt,
    total_return_tax,
    total_net_loss,
    AVG(distinct_ticket_cnt) OVER () AS avg_ticket_cnt_overall
FROM final
ORDER BY total_net_loss DESC, distinct_ticket_cnt DESC
LIMIT 100
