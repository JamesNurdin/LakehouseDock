WITH returns_agg AS (
    SELECT
        d_return.d_year AS return_year,
        d_return.d_month_seq AS return_month_seq,
        d_return.d_week_seq AS return_week_seq,
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_manager AS store_manager,
        s.s_floor_space AS store_floor_space,
        d_store.d_date AS store_closed_date,
        hd_refund.hd_dep_count AS refunded_dep_count,
        hd_return.hd_vehicle_count AS returning_vehicle_count,
        hd_refund.hd_buy_potential AS refunded_buy_potential,
        wp.wp_type AS page_type,
        wp.wp_url AS page_url,
        d_creation.d_date AS page_creation_date,
        d_access.d_date AS page_access_date,
        COUNT(DISTINCT wr.wr_order_number) AS num_orders,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        AVG(wr.wr_fee) AS avg_fee,
        SUM(wr.wr_return_quantity) AS total_quantity
    FROM web_returns wr
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN household_demographics hd_refund ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN household_demographics hd_return ON wr.wr_returning_hdemo_sk = hd_return.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN store s ON s.s_closed_date_sk = d_return.d_date_sk
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    LEFT JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    LEFT JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    GROUP BY
        d_return.d_year,
        d_return.d_month_seq,
        d_return.d_week_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_manager,
        s.s_floor_space,
        d_store.d_date,
        hd_refund.hd_dep_count,
        hd_return.hd_vehicle_count,
        hd_refund.hd_buy_potential,
        wp.wp_type,
        wp.wp_url,
        d_creation.d_date,
        d_access.d_date
)
SELECT
    return_year,
    return_month_seq,
    return_week_seq,
    store_id,
    store_name,
    store_manager,
    store_floor_space,
    store_closed_date,
    refunded_dep_count,
    returning_vehicle_count,
    refunded_buy_potential,
    page_type,
    page_url,
    page_creation_date,
    page_access_date,
    num_orders,
    total_return_amount,
    total_return_tax,
    avg_fee,
    total_quantity,
    ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_return_amount DESC) AS store_return_rank
FROM returns_agg
ORDER BY total_return_amount DESC
LIMIT 100
