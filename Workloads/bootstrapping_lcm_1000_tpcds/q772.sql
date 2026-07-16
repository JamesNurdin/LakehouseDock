WITH enriched_returns AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_ret.d_date AS return_date,
        ca_ref.ca_city AS refunded_city,
        ca_ret.ca_city AS returning_city,
        wp.wp_url,
        wp.wp_type,
        d_cre.d_current_month AS page_creation_month,
        d_acc.d_day_name AS page_access_day,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_return_tax,
        wr.wr_fee,
        wr.wr_return_ship_cost
    FROM web_returns wr
    JOIN customer_address ca_ref
      ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
      ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cre
      ON wp.wp_creation_date_sk = d_cre.d_date_sk
    JOIN date_dim d_acc
      ON wp.wp_access_date_sk = d_acc.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2022
)
SELECT
    s_store_id,
    s_city,
    s_state,
    return_date,
    refunded_city,
    returning_city,
    wp_url,
    wp_type,
    page_creation_month,
    page_access_day,
    COUNT(*) AS num_returns,
    SUM(wr_return_amt) AS total_return_amt,
    SUM(wr_net_loss) AS total_net_loss,
    AVG(wr_return_tax) AS avg_return_tax,
    SUM(wr_fee) AS total_fee,
    SUM(wr_return_ship_cost) AS total_ship_cost
FROM enriched_returns
GROUP BY
    s_store_id,
    s_city,
    s_state,
    return_date,
    refunded_city,
    returning_city,
    wp_url,
    wp_type,
    page_creation_month,
    page_access_day
ORDER BY total_return_amt DESC
LIMIT 100
