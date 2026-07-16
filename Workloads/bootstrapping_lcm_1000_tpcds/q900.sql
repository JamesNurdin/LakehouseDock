WITH wr_dates AS (
    SELECT
        wr.*,
        d_ret.d_date AS return_date,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq
    FROM web_returns wr
    INNER JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
),
promo_dates AS (
    SELECT
        p.*,
        d_ps.d_date AS promo_start_date,
        d_pe.d_date AS promo_end_date
    FROM promotion p
    INNER JOIN date_dim d_ps
        ON p.p_start_date_sk = d_ps.d_date_sk
    INNER JOIN date_dim d_pe
        ON p.p_end_date_sk = d_pe.d_date_sk
),
catalog_dates AS (
    SELECT
        cp.*,
        d_cs.d_date AS cp_start_date,
        d_ce.d_date AS cp_end_date
    FROM catalog_page cp
    INNER JOIN date_dim d_cs
        ON cp.cp_start_date_sk = d_cs.d_date_sk
    INNER JOIN date_dim d_ce
        ON cp.cp_end_date_sk = d_ce.d_date_sk
),
store_dates AS (
    SELECT
        s.*,
        d_s.d_date AS store_closed_date,
        d_s.d_year AS store_closed_year
    FROM store s
    INNER JOIN date_dim d_s
        ON s.s_closed_date_sk = d_s.d_date_sk
)
SELECT
    p.p_promo_name,
    p.p_cost,
    cp.cp_catalog_number,
    cp.cp_type,
    s.s_state,
    s.s_city,
    wrd.return_year,
    wrd.return_month_seq,
    SUM(wrd.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT wrd.wr_order_number) AS total_returns,
    AVG(wrd.wr_return_quantity) AS avg_return_quantity,
    SUM(wrd.wr_return_amt) AS total_return_amount,
    MIN(cp.cp_catalog_page_number) AS min_catalog_page_number,
    MAX(p.p_response_target) AS max_response_target
FROM wr_dates wrd
INNER JOIN promo_dates p
    ON wrd.return_date BETWEEN p.promo_start_date AND p.promo_end_date
INNER JOIN catalog_dates cp
    ON wrd.return_date BETWEEN cp.cp_start_date AND cp.cp_end_date
INNER JOIN store_dates s
    ON wrd.return_year = s.store_closed_year
WHERE wrd.return_date IS NOT NULL
GROUP BY
    p.p_promo_name,
    p.p_cost,
    cp.cp_catalog_number,
    cp.cp_type,
    s.s_state,
    s.s_city,
    wrd.return_year,
    wrd.return_month_seq
HAVING SUM(wrd.wr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
