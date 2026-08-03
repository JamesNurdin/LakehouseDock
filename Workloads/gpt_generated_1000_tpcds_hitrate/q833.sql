/*
Goal: Analyze web return amounts by store country and promotion over time, showing subtotals and a grand total, differentiating between automatically generated and manually created web pages, and providing overall average return amount.
The query joins all seven selected tables, re‑uses the date_dim and promotion tables under different aliases, uses more than nine join clauses, includes a CASE expression, a scalar subquery, a ROW_NUMBER window function, a GROUP BY ROLLUP for subtotals, a HAVING filter, and combines two aggregated result sets with UNION DISTINCT.
*/
WITH
    -- Aliases for the date dimension used in different roles
    dr_return      AS (SELECT * FROM date_dim),
    dr_wp_creation AS (SELECT * FROM date_dim),
    dr_wp_access   AS (SELECT * FROM date_dim),
    dr_store       AS (SELECT * FROM date_dim),
    dr_promo_start AS (SELECT * FROM date_dim),
    dr_promo_end   AS (SELECT * FROM date_dim),
    dr_ws_open     AS (SELECT * FROM date_dim),
    dr_ws_close    AS (SELECT * FROM date_dim)

SELECT
    s.s_country                              AS store_country,
    p_start.p_promo_name                     AS promo_name,
    dr.d_date                                 AS return_date,
    SUM(wr.wr_return_amt)                    AS total_return_amt,
    SUM(wr.wr_return_tax)                    AS total_return_tax,
    COUNT(*)                                  AS return_cnt,
    CASE WHEN SUM(wr.wr_return_amt) > 5000 THEN 'High' ELSE 'Low' END AS return_level,
    ROW_NUMBER() OVER (ORDER BY SUM(wr.wr_return_amt) DESC) AS rn,
    (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2) AS avg_return_amt_overall
FROM
    web_returns wr
    JOIN dr_return        dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN time_dim        t  ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page        wp ON wr.wr_web_page_sk   = wp.wp_web_page_sk
    JOIN dr_wp_creation   dr_wp_creation ON wp.wp_creation_date_sk = dr_wp_creation.d_date_sk
    JOIN dr_wp_access     dr_wp_access   ON wp.wp_access_date_sk   = dr_wp_access.d_date_sk
    JOIN store          s  ON s.s_closed_date_sk = dr.d_date_sk
    JOIN promotion      p_start ON p_start.p_start_date_sk = dr.d_date_sk
    JOIN promotion      p_end   ON p_end.p_end_date_sk   = dr.d_date_sk
    JOIN web_site       ws_open ON ws_open.web_open_date_sk  = dr.d_date_sk
    JOIN web_site       ws_close ON ws_close.web_close_date_sk = dr.d_date_sk
WHERE
    wp.wp_autogen_flag = 'Y'
    AND t.t_hour BETWEEN 9 AND 17
GROUP BY ROLLUP (s.s_country, p_start.p_promo_name, dr.d_date)
HAVING SUM(wr.wr_return_amt) > 1000

UNION DISTINCT

SELECT
    s.s_country,
    p_start.p_promo_name,
    dr.d_date,
    SUM(wr.wr_return_amt),
    SUM(wr.wr_return_tax),
    COUNT(*),
    CASE WHEN SUM(wr.wr_return_amt) > 5000 THEN 'High' ELSE 'Low' END,
    ROW_NUMBER() OVER (ORDER BY SUM(wr.wr_return_amt) DESC),
    (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2)
FROM
    web_returns wr
    JOIN dr_return        dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN time_dim        t  ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page        wp ON wr.wr_web_page_sk   = wp.wp_web_page_sk
    JOIN dr_wp_creation   dr_wp_creation ON wp.wp_creation_date_sk = dr_wp_creation.d_date_sk
    JOIN dr_wp_access     dr_wp_access   ON wp.wp_access_date_sk   = dr_wp_access.d_date_sk
    JOIN store          s  ON s.s_closed_date_sk = dr.d_date_sk
    JOIN promotion      p_start ON p_start.p_start_date_sk = dr.d_date_sk
    JOIN promotion      p_end   ON p_end.p_end_date_sk   = dr.d_date_sk
    JOIN web_site       ws_open ON ws_open.web_open_date_sk  = dr.d_date_sk
    JOIN web_site       ws_close ON ws_close.web_close_date_sk = dr.d_date_sk
WHERE
    wp.wp_autogen_flag = 'N'
    AND t.t_hour NOT BETWEEN 0 AND 8
GROUP BY ROLLUP (s.s_country, p_start.p_promo_name, dr.d_date)
HAVING SUM(wr.wr_return_amt) > 0
