SELECT
    s.s_store_id,
    s.s_state,
    i.i_category,
    i.i_brand,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_date,
    d_closed.d_date AS store_closed_date,
    d_access.d_week_seq,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(CASE WHEN wp.wp_type = 'product' THEN 1 ELSE 0 END) AS product_page_count,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(*) AS return_count
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_ret.d_year = 2022
  AND s.s_state = 'TX'
  AND wp.wp_type IN ('product', 'category')
GROUP BY
    s.s_store_id,
    s.s_state,
    i.i_category,
    i.i_brand,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_date,
    d_closed.d_date,
    d_access.d_week_seq
ORDER BY total_net_loss DESC
LIMIT 100
