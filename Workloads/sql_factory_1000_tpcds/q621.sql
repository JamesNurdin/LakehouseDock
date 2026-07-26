WITH page_returns AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_link_count,
        wr.wr_returned_date_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_amt) AS web_return_amt,
        SUM(wr.wr_return_quantity) AS web_return_qty
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY wp.wp_web_page_sk, wp.wp_url, wp.wp_type, wp.wp_char_count, wp.wp_link_count, wr.wr_returned_date_sk
),
store_daily AS (
    SELECT
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_amt) AS store_return_amt
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk
),
page_store AS (
    SELECT
        pr.wp_web_page_sk,
        SUM(COALESCE(sd.store_net_loss, 0)) AS total_store_net_loss,
        SUM(COALESCE(sd.store_return_amt, 0)) AS total_store_return_amt
    FROM page_returns pr
    LEFT JOIN store_daily sd ON pr.wr_returned_date_sk = sd.sr_returned_date_sk
    GROUP BY pr.wp_web_page_sk
),
page_creation AS (
    SELECT
        wp.wp_web_page_sk,
        d.d_year,
        d.d_month_seq
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
)
SELECT
    t.wp_web_page_sk,
    t.wp_url,
    t.wp_type,
    t.total_web_net_loss,
    t.total_web_return_amt,
    t.total_web_return_qty,
    t.total_store_net_loss,
    t.total_store_return_amt,
    DENSE_RANK() OVER (ORDER BY t.total_web_net_loss DESC) AS loss_rank,
    CASE
        WHEN t.total_web_net_loss > 5000 THEN 'High Loss'
        WHEN t.total_web_net_loss BETWEEN 2000 AND 5000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    CASE
        WHEN t.total_web_return_amt = 0 THEN 0
        ELSE t.total_web_net_loss / t.total_web_return_amt
    END AS loss_ratio
FROM (
    SELECT
        pc.wp_web_page_sk,
        pr.wp_url,
        pr.wp_type,
        SUM(pr.web_net_loss) AS total_web_net_loss,
        SUM(pr.web_return_amt) AS total_web_return_amt,
        SUM(pr.web_return_qty) AS total_web_return_qty,
        ps.total_store_net_loss,
        ps.total_store_return_amt
    FROM page_returns pr
    JOIN page_creation pc ON pr.wp_web_page_sk = pc.wp_web_page_sk
    JOIN page_store ps ON pr.wp_web_page_sk = ps.wp_web_page_sk
    WHERE pc.d_year = 2022
    GROUP BY pc.wp_web_page_sk, pr.wp_url, pr.wp_type, ps.total_store_net_loss, ps.total_store_return_amt
) t
ORDER BY loss_rank
LIMIT 5
