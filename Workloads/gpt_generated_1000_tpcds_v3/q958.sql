WITH joined_data AS (
    SELECT
        td.t_hour,
        td.t_shift,
        wp.wp_type,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_quantity AS ss_quantity,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        cr.cr_net_loss,
        wr.wr_net_loss
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND wp.wp_type = 'content'
      AND wp.wp_rec_start_date >= DATE '2000-01-01'
), aggregated AS (
    SELECT
        t_hour,
        wp_type,
        SUM(ss_ext_sales_price) AS total_sales_price,
        SUM(ss_ext_discount_amt) AS total_discount,
        SUM(ss_quantity) AS total_quantity_sold,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(cr_return_quantity) AS total_catalog_return_qty,
        SUM(wr_return_amt) AS total_web_return_amount,
        SUM(wr_return_quantity) AS total_web_return_qty,
        SUM(cr_net_loss) AS total_catalog_net_loss,
        SUM(wr_net_loss) AS total_web_net_loss,
        (SUM(ss_ext_sales_price) - SUM(cr_return_amount) - SUM(wr_return_amt)) AS net_revenue,
        (SUM(cr_net_loss) + SUM(wr_net_loss)) AS total_net_loss
    FROM joined_data
    GROUP BY t_hour, wp_type
)
SELECT
    t_hour,
    AVG(total_net_loss) AS avg_net_loss,
    SUM(total_sales_price) AS sum_sales_price,
    SUM(total_catalog_return_amount) AS sum_catalog_return_amount,
    SUM(total_web_return_amount) AS sum_web_return_amount
FROM aggregated
GROUP BY t_hour
HAVING AVG(total_net_loss) > 1000
ORDER BY avg_net_loss DESC
LIMIT 100
