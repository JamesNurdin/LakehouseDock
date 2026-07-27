WITH sr_agg AS (
    SELECT
        sr_returned_date_sk,
        sr_store_sk,
        sr_return_time_sk,
        sr_item_sk,
        SUM(sr_return_amt)        AS total_return_amt,
        SUM(sr_return_quantity)   AS total_quantity,
        COUNT(*)                  AS return_cnt
    FROM store_returns
    GROUP BY
        sr_returned_date_sk,
        sr_store_sk,
        sr_return_time_sk,
        sr_item_sk
)
SELECT
    d_ret.d_date,
    s.s_store_name,
    i.i_product_name,
    t.t_hour,
    ws.web_name,
    SUM(sa.total_return_amt) AS sum_return_amt,
    SUM(sa.total_quantity)   AS sum_quantity,
    COUNT(*)                 AS num_rows,
    MIN(sa.total_return_amt) AS min_return_amt,
    MAX(sa.total_return_amt) AS max_return_amt,
    AVG(sa.total_return_amt) AS avg_return_amt,
    (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
    ) AS max_item_promo_cost
FROM sr_agg sa
JOIN date_dim d_ret
    ON sa.sr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON sa.sr_return_time_sk = t.t_time_sk
JOIN item i
    ON sa.sr_item_sk = i.i_item_sk
JOIN store s
    ON sa.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
    AND p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_site_close
    ON ws.web_close_date_sk = d_site_close.d_date_sk
WHERE
    d_ret.d_year = 2001
    AND i.i_wholesale_cost > 1.00
    AND p.p_channel_email = 'Y'
    AND s.s_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND d_ret.d_holiday = 'N'
GROUP BY
    d_ret.d_date,
    s.s_store_name,
    i.i_product_name,
    t.t_hour,
    ws.web_name,
    i.i_item_sk
LIMIT 100
