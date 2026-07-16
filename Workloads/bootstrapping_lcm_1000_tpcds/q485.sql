WITH agg AS (
    SELECT
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        s.s_state,
        s.s_city,
        COUNT(DISTINCT wr.wr_order_number) AS num_orders,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_fee) AS avg_fee,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
        SUM(wp.wp_image_count) AS total_image_count,
        MAX(wp.wp_char_count) AS max_char_count,
        SUM(CASE WHEN wp.wp_type = 'product' THEN 1 ELSE 0 END) AS product_page_returns,
        SUM(CASE WHEN wp.wp_type = 'advertisement' THEN 1 ELSE 0 END) AS ad_page_returns,
        SUM(wr.wr_return_tax) AS total_tax,
        d_cre.d_date AS page_creation_date,
        d_acc.d_date AS page_access_date,
        SUM(s.s_floor_space) AS total_floor_space
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_cre ON wp.wp_creation_date_sk = d_cre.d_date_sk
    JOIN date_dim d_acc ON wp.wp_access_date_sk = d_acc.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year BETWEEN 2015 AND 2020
      AND s.s_state IS NOT NULL
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_state,
        s.s_city,
        d_cre.d_date,
        d_acc.d_date
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    ranked.return_year,
    ranked.return_month,
    ranked.s_state,
    ranked.s_city,
    ranked.num_orders,
    ranked.total_return_amount,
    ranked.total_net_loss,
    ranked.avg_fee,
    ranked.distinct_pages,
    ranked.total_image_count,
    ranked.max_char_count,
    ranked.product_page_returns,
    ranked.ad_page_returns,
    ranked.total_tax,
    ranked.page_creation_date,
    ranked.page_access_date,
    ranked.total_floor_space,
    ranked.state_rank
FROM (
    SELECT
        agg.return_year,
        agg.return_month,
        agg.s_state,
        agg.s_city,
        agg.num_orders,
        agg.total_return_amount,
        agg.total_net_loss,
        agg.avg_fee,
        agg.distinct_pages,
        agg.total_image_count,
        agg.max_char_count,
        agg.product_page_returns,
        agg.ad_page_returns,
        agg.total_tax,
        agg.page_creation_date,
        agg.page_access_date,
        agg.total_floor_space,
        ROW_NUMBER() OVER (PARTITION BY agg.s_state ORDER BY agg.total_return_amount DESC) AS state_rank
    FROM agg
) ranked
WHERE ranked.state_rank <= 5
ORDER BY ranked.s_state, ranked.state_rank
LIMIT 100
