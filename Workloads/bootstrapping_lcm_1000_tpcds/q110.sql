WITH aggregated AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.s_store_name,
        s.s_city,
        w.wp_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        MIN(sold.d_date) AS first_sold_date,
        MAX(ship.d_date) AS last_ship_date,
        DATE_DIFF('day', MIN(sold.d_date), MAX(ship.d_date)) AS sales_cycle_days,
        w.wp_url,
        wp_creation.d_year AS page_creation_year,
        wp_access.d_year AS page_access_year
    FROM catalog_sales cs
    JOIN date_dim sold ON cs.cs_sold_date_sk = sold.d_date_sk
    JOIN date_dim ship ON cs.cs_ship_date_sk = ship.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN store s ON s.s_closed_date_sk = sold.d_date_sk
    JOIN web_page w ON w.wp_customer_sk = c.c_customer_sk
    JOIN date_dim wp_creation ON w.wp_creation_date_sk = wp_creation.d_date_sk
    JOIN date_dim wp_access ON w.wp_access_date_sk = wp_access.d_date_sk
    WHERE sold.d_year = 2020
      AND s.s_state = 'CA'
      AND w.wp_type = 'article'
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.s_store_name,
        s.s_city,
        w.wp_type,
        w.wp_url,
        wp_creation.d_year,
        wp_access.d_year
    HAVING SUM(cs.cs_net_profit) > 1000
)
SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_name ORDER BY a.total_net_profit DESC) AS profit_rank_in_store,
    CASE
        WHEN a.total_net_profit > 5000 THEN 'high'
        WHEN a.total_net_profit > 1000 THEN 'medium'
        ELSE 'low'
    END AS profit_category
FROM aggregated a
ORDER BY a.total_net_profit DESC
LIMIT 100
