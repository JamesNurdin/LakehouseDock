WITH returns_agg AS (
    SELECT
        sr.sr_store_sk,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_ret.d_quarter_name,
        t.t_shift,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        SUM(sr.sr_store_credit) AS total_store_credit,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_return_tax) AS total_return_tax,
        SUM(sr.sr_return_ship_cost) AS total_return_ship_cost,
        SUM(CASE WHEN sr.sr_fee > 0 THEN sr.sr_fee ELSE 0 END) AS total_fee,
        SUM(CASE WHEN sr.sr_return_quantity > 5 THEN sr.sr_return_amt ELSE 0 END) AS high_qty_return_amount
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    GROUP BY
        sr.sr_store_sk,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_ret.d_quarter_name,
        t.t_shift
),
page_agg AS (
    SELECT
        d_create.d_year,
        d_create.d_month_seq,
        d_create.d_quarter_name,
        COUNT(DISTINCT wp.wp_web_page_sk) AS total_pages,
        SUM(wp.wp_image_count) AS total_images,
        SUM(wp.wp_link_count) AS total_links,
        SUM(wp.wp_char_count) AS total_characters,
        SUM(CASE WHEN wp.wp_type = 'article' THEN 1 ELSE 0 END) AS article_pages,
        SUM(CASE WHEN wp.wp_type = 'advertisement' THEN 1 ELSE 0 END) AS ad_pages,
        MIN(d_access.d_date) AS earliest_access_date
    FROM web_page wp
    JOIN date_dim d_create
        ON wp.wp_creation_date_sk = d_create.d_date_sk
    LEFT JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    GROUP BY
        d_create.d_year,
        d_create.d_month_seq,
        d_create.d_quarter_name
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ra.d_year,
    ra.d_month_seq,
    ra.d_quarter_name,
    ra.t_shift,
    ra.total_returns,
    ra.total_return_amount,
    ra.total_net_loss,
    ra.avg_return_quantity,
    ra.total_store_credit,
    ra.total_refunded_cash,
    ra.total_return_tax,
    ra.total_return_ship_cost,
    ra.total_fee,
    ra.high_qty_return_amount,
    pa.total_pages,
    pa.total_images,
    pa.total_links,
    pa.total_characters,
    pa.article_pages,
    pa.ad_pages,
    MIN(d_close.d_date) AS store_closed_date
FROM returns_agg ra
JOIN store s
    ON ra.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_close
    ON s.s_closed_date_sk = d_close.d_date_sk
LEFT JOIN page_agg pa
    ON ra.d_year = pa.d_year
   AND ra.d_month_seq = pa.d_month_seq
   AND ra.d_quarter_name = pa.d_quarter_name
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ra.d_year,
    ra.d_month_seq,
    ra.d_quarter_name,
    ra.t_shift,
    ra.total_returns,
    ra.total_return_amount,
    ra.total_net_loss,
    ra.avg_return_quantity,
    ra.total_store_credit,
    ra.total_refunded_cash,
    ra.total_return_tax,
    ra.total_return_ship_cost,
    ra.total_fee,
    ra.high_qty_return_amount,
    pa.total_pages,
    pa.total_images,
    pa.total_links,
    pa.total_characters,
    pa.article_pages,
    pa.ad_pages
ORDER BY ra.total_return_amount DESC
LIMIT 100
