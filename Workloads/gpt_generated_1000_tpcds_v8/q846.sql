WITH intersect_customers AS (
        SELECT cs.cs_bill_customer_sk AS cust_sk
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 5
        INTERSECT
        SELECT wr.wr_refunded_customer_sk
        FROM web_returns wr
        WHERE wr.wr_return_quantity > 1
    ),
    base AS (
        SELECT
            d.d_year,
            s.s_state,
            c.c_customer_sk,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            cs.cs_quantity,
            cs.cs_promo_sk,
            ca.ca_state,
            hd.hd_vehicle_count,
            ib.ib_lower_bound,
            inv.inv_quantity_on_hand,
            r.r_reason_desc,
            wp.wp_image_count,
            wr.wr_net_loss,
            t.t_hour,
            d.d_date_sk
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE c.c_birth_country = 'United States'
          AND d.d_year = 2001
          AND t.t_hour BETWEEN 9 AND 17
          AND s.s_state = 'CA'
          AND ib.ib_lower_bound >= 50000
          AND cs.cs_promo_sk = 945
          AND c.c_customer_sk IN (SELECT cust_sk FROM intersect_customers)
          AND EXISTS (
              SELECT 1 FROM store_sales ss2
              WHERE ss2.ss_customer_sk = c.c_customer_sk
                AND ss2.ss_quantity > 10
          )
    ),
    agg1 AS (
        SELECT d_year, s_state,
               SUM(cs_ext_sales_price) AS total_sales,
               AVG(cs_net_profit) AS avg_profit,
               COUNT(DISTINCT c_customer_sk) AS cust_cnt
        FROM base
        WHERE cs_quantity > 2
        GROUP BY ROLLUP(d_year, s_state)
    ),
    agg2 AS (
        SELECT d_year, s_state,
               SUM(cs_ext_sales_price) AS total_sales,
               AVG(cs_net_profit) AS avg_profit,
               COUNT(DISTINCT c_customer_sk) AS cust_cnt
        FROM base
        WHERE cs_quantity <= 2
        GROUP BY ROLLUP(d_year, s_state)
    ),
    union_agg AS (
        SELECT * FROM agg1
        UNION DISTINCT
        SELECT * FROM agg2
    )
SELECT
    d_year,
    s_state,
    total_sales,
    avg_profit,
    cust_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
    (
        SELECT AVG(total_sales)
        FROM agg1 a1
        WHERE a1.d_year = union_agg.d_year
    ) AS avg_year_total_sales
FROM union_agg
ORDER BY d_year DESC, s_state
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
