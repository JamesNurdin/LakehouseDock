WITH sales_agg AS (
    SELECT
        d.d_year,
        ca.ca_state,
        hd.hd_buy_potential,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_paid_inc_ship) AS avg_net_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND ca.ca_street_type IN ('St', 'Rd', 'Ln')
      AND hd.hd_buy_potential IN ('501-1000', '>10000')
      AND cs.cs_net_paid_inc_ship > 3000
      AND t.t_hour BETWEEN 9 AND 17
      AND w.w_state = 'CA'
    GROUP BY d.d_year, ca.ca_state, hd.hd_buy_potential
)
SELECT
    sa.d_year,
    sa.ca_state,
    sa.hd_buy_potential,
    sa.total_sales,
    sa.avg_net_paid,
    sa.order_cnt,
    RANK() OVER (ORDER BY sa.total_sales DESC) AS sales_rank,
    SUM(sa.total_sales) OVER (PARTITION BY sa.d_year ORDER BY sa.total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
    (SELECT MAX(total_sales) FROM sales_agg) AS max_sales_overall
FROM sales_agg sa
WHERE sa.total_sales > (SELECT AVG(total_sales) FROM sales_agg)
ORDER BY sa.total_sales DESC
LIMIT 100
