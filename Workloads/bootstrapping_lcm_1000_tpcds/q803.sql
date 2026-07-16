WITH aggregated AS (
    SELECT
        cs.cs_item_sk,
        s.s_state,
        s.s_city,
        s.s_store_sk,
        hd_bill.hd_income_band_sk,
        hd_ship.hd_vehicle_count,
        sold.d_year AS sold_year,
        sold.d_month_seq AS sold_month_seq,
        ship.d_year AS ship_year,
        ship.d_month_seq AS ship_month_seq,
        wp.wp_type,
        wp.wp_url,
        access.d_year AS access_year,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim sold ON cs.cs_sold_date_sk = sold.d_date_sk
    JOIN date_dim ship ON cs.cs_ship_date_sk = ship.d_date_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN store s ON s.s_closed_date_sk = sold.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = sold.d_date_sk
    JOIN date_dim access ON wp.wp_access_date_sk = access.d_date_sk
    WHERE sold.d_year = 2022
      AND s.s_state = 'CA'
      AND wp.wp_type = 'product'
    GROUP BY
        cs.cs_item_sk,
        s.s_state,
        s.s_city,
        s.s_store_sk,
        hd_bill.hd_income_band_sk,
        hd_ship.hd_vehicle_count,
        sold.d_year,
        sold.d_month_seq,
        ship.d_year,
        ship.d_month_seq,
        wp.wp_type,
        wp.wp_url,
        access.d_year
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT
    a.cs_item_sk,
    a.s_state,
    a.s_city,
    a.s_store_sk,
    a.hd_income_band_sk,
    a.hd_vehicle_count,
    a.sold_year,
    a.sold_month_seq,
    a.ship_year,
    a.ship_month_seq,
    a.wp_type,
    a.wp_url,
    a.access_year,
    a.num_orders,
    a.total_net_paid,
    a.avg_discount_amount,
    a.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_sk ORDER BY a.total_net_paid DESC) AS item_rank_in_store
FROM aggregated a
ORDER BY a.total_net_paid DESC
LIMIT 100
