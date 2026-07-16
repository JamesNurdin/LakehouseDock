WITH sales_agg AS (
    SELECT
        s.cs_item_sk,
        s.cs_order_number,
        SUM(s.cs_net_paid) AS total_net_paid,
        SUM(s.cs_net_profit) AS total_net_profit,
        MIN(d_sold.d_year) AS sold_year,
        MIN(d_ship.d_day_name) AS ship_day_name
    FROM catalog_sales s
    JOIN date_dim d_sold ON s.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON s.cs_ship_date_sk = d_ship.d_date_sk
    GROUP BY s.cs_item_sk, s.cs_order_number
)
SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    sa.sold_year,
    sa.ship_day_name,
    st.s_store_name,
    st.s_state,
    wp.wp_url,
    wp.wp_type,
    SUM(r.cr_return_amount) AS total_return_amount,
    SUM(r.cr_net_loss) AS total_net_loss,
    SUM(sa.total_net_paid) AS total_sales_net_paid,
    SUM(sa.total_net_profit) AS total_sales_net_profit,
    COUNT(DISTINCT r.cr_order_number) AS distinct_returns,
    ROW_NUMBER() OVER (PARTITION BY st.s_store_id ORDER BY SUM(r.cr_return_amount) DESC) AS return_rank_by_store
FROM catalog_returns r
JOIN sales_agg sa
    ON r.cr_item_sk = sa.cs_item_sk
   AND r.cr_order_number = sa.cs_order_number
JOIN date_dim d_ret
    ON r.cr_returned_date_sk = d_ret.d_date_sk
JOIN store st
    ON st.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    sa.sold_year,
    sa.ship_day_name,
    st.s_store_name,
    st.s_state,
    wp.wp_url,
    wp.wp_type,
    st.s_store_id
HAVING SUM(r.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
