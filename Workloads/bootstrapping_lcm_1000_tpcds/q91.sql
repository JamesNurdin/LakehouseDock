WITH returns AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_return_net_loss,
        d_closed.d_year          AS store_closed_year,
        d_closed.d_month_seq    AS store_closed_month_seq
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_closed.d_year,
        d_closed.d_month_seq
),
sales AS (
    SELECT
        d_sold.d_year,
        d_sold.d_month_seq,
        COUNT(*) AS sales_cnt,
        SUM(ws.ws_net_profit)           AS total_net_profit,
        SUM(ws.ws_ext_sales_price)      AS total_sales_price,
        SUM(ws.ws_ext_ship_cost)        AS total_ship_cost,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_pages_sold,
        COUNT(DISTINCT wp.wp_type)      AS distinct_page_types,
        AVG(wp.wp_image_count)          AS avg_image_count_of_sold_pages
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq
),
pages AS (
    SELECT
        d_cre.d_year,
        d_cre.d_month_seq,
        COUNT(DISTINCT wp.wp_web_page_sk) AS created_pages_cnt,
        AVG(wp.wp_image_count)            AS avg_image_count,
        COUNT(*)                          AS total_access_cnt
    FROM web_page wp
    JOIN date_dim d_cre
        ON wp.wp_creation_date_sk = d_cre.d_date_sk
    JOIN date_dim d_acc
        ON wp.wp_access_date_sk = d_acc.d_date_sk
    GROUP BY
        d_cre.d_year,
        d_cre.d_month_seq
)
SELECT
    r.s_store_name,
    r.d_year,
    r.d_month_seq,
    r.return_cnt,
    r.total_return_amt,
    r.total_return_net_loss,
    r.store_closed_year,
    r.store_closed_month_seq,
    s.sales_cnt,
    s.total_net_profit,
    s.total_sales_price,
    s.total_ship_cost,
    s.distinct_pages_sold,
    s.distinct_page_types,
    s.avg_image_count_of_sold_pages,
    p.created_pages_cnt,
    p.avg_image_count,
    p.total_access_cnt
FROM returns r
JOIN sales s
    ON r.d_year = s.d_year
   AND r.d_month_seq = s.d_month_seq
JOIN pages p
    ON r.d_year = p.d_year
   AND r.d_month_seq = p.d_month_seq
ORDER BY r.total_return_net_loss DESC
LIMIT 50
