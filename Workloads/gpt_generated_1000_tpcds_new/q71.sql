WITH
    base AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_ship_date_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            d.d_year,
            d.d_month_seq,
            hd.hd_income_band_sk,
            hd.hd_vehicle_count,
            s.s_store_sk,
            s.s_state,
            wp.wp_web_page_sk,
            wp.wp_image_count,
            CASE WHEN cs.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
        FROM catalog_sales cs
        JOIN date_dim d
          ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd
          ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN store s
          ON s.s_closed_date_sk = d.d_date_sk
        JOIN web_page wp
          ON wp.wp_creation_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 1999 AND 2001
          AND cs.cs_ext_sales_price > 1000
          AND hd.hd_vehicle_count >= 2
          AND s.s_state = 'CA'
          AND wp.wp_image_count BETWEEN 1 AND 5
    ),
    intersected_orders AS (
        SELECT cs_order_number FROM catalog_sales
        WHERE cs_coupon_amt > 0 AND cs_ext_discount_amt > 1000
        INTERSECT
        SELECT cs_order_number FROM catalog_sales
        WHERE cs_ext_wholesale_cost > 1000 AND cs_quantity >= 2
    ),
    agg AS (
        SELECT
            d_year,
            s_state,
            SUM(cs_ext_sales_price) AS total_sales,
            SUM(cs_net_profit) AS total_profit,
            COUNT(*) AS sales_cnt
        FROM base
        GROUP BY d_year, s_state
        HAVING SUM(cs_ext_sales_price) > 5000
    ),
    order_stats AS (
        SELECT
            d.d_year,
            s.s_state,
            COUNT(*) AS intersect_cnt
        FROM catalog_sales cs
        JOIN date_dim d
          ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN store s
          ON s.s_closed_date_sk = d.d_date_sk
        WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersected_orders)
        GROUP BY d.d_year, s.s_state
    )
SELECT
    a.d_year,
    a.s_state,
    a.total_sales,
    a.total_profit,
    a.sales_cnt,
    os.intersect_cnt,
    CASE WHEN a.total_profit / NULLIF(a.sales_cnt, 0) > 100 THEN 'HIGH' ELSE 'LOW' END AS profit_per_sale_category
FROM agg a
JOIN order_stats os
  ON a.d_year = os.d_year AND a.s_state = os.s_state
ORDER BY a.total_sales DESC
LIMIT 100
