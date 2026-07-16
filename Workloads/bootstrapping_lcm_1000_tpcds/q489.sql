WITH joined_data AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_return_tax,
        cr.cr_item_sk,
        cr.cr_order_number,
        d_ret.d_date AS return_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_ret.d_week_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_market_desc,
        wp.wp_web_page_id,
        wp.wp_type,
        wp.wp_url,
        wp.wp_char_count,
        wp.wp_image_count,
        d_acc.d_date AS access_date,
        cr.cr_net_loss / NULLIF(cr.cr_return_quantity, 0) AS net_loss_per_item,
        CASE
            WHEN cr.cr_net_loss / NULLIF(cr.cr_return_quantity, 0) > 10 THEN 'High'
            WHEN cr.cr_net_loss / NULLIF(cr.cr_return_quantity, 0) > 0 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_acc
        ON wp.wp_access_date_sk = d_acc.d_date_sk
    WHERE d_ret.d_year BETWEEN 2000 AND 2005
),
aggregated AS (
    SELECT
        s_store_id,
        s_store_name,
        s_city,
        s_state,
        d_year,
        d_month_seq,
        wp_web_page_id,
        wp_type,
        loss_category,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_fee) AS total_fee,
        SUM(cr_return_tax) AS total_tax,
        SUM(cr_return_quantity) AS total_quantity,
        AVG(net_loss_per_item) AS avg_net_loss_per_item,
        COUNT(*) AS count_returns,
        MAX(cr_return_amount) AS max_return_amount,
        MIN(cr_return_amount) AS min_return_amount
    FROM joined_data
    GROUP BY
        s_store_id,
        s_store_name,
        s_city,
        s_state,
        d_year,
        d_month_seq,
        wp_web_page_id,
        wp_type,
        loss_category
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    d_year,
    d_month_seq,
    wp_web_page_id,
    wp_type,
    loss_category,
    total_net_loss,
    total_return_amount,
    total_fee,
    total_tax,
    total_quantity,
    avg_net_loss_per_item,
    count_returns,
    max_return_amount,
    min_return_amount,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS rank_store_by_year,
    SUM(total_net_loss) OVER (PARTITION BY s_store_id ORDER BY d_year, d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss
FROM aggregated
WHERE total_net_loss > 0
ORDER BY total_net_loss DESC
LIMIT 200
