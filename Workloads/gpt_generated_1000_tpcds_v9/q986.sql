WITH base AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        wr.wr_return_amt,
        i.i_brand,
        s.s_state,
        d.d_year,
        t.t_hour,
        hd_cs.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cd_cs.cd_credit_rating,
        inv.inv_quantity_on_hand,
        wp.wp_type
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd_cs
      ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
    JOIN household_demographics hd_cs
      ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN income_band ib
      ON hd_cs.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_sold_time_sk = t.t_time_sk
     AND ss.ss_item_sk = i.i_item_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd_ss
      ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss
      ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
     AND inv.inv_item_sk = i.i_item_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2000
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'CA'
      AND cs.cs_ext_sales_price > 2000
      AND t.t_hour BETWEEN 8 AND 18
      AND hd_cs.hd_vehicle_count >= 1
      AND cd_cs.cd_credit_rating = 'Good'
      AND EXISTS (
          SELECT 1 FROM web_returns wr2
          WHERE wr2.wr_item_sk = i.i_item_sk
            AND wr2.wr_return_amt > 100
      )
),
agg AS (
    SELECT
        d_year,
        s_state,
        i_brand,
        cs_sold_date_sk,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(wr_return_amt) AS total_returns,
        AVG(cs_net_profit) AS avg_catalog_profit,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        CASE
            WHEN SUM(cs_net_profit) > 0 THEN 'Positive'
            WHEN SUM(cs_net_profit) = 0 THEN 'Zero'
            ELSE 'Negative'
        END AS profit_category
    FROM base
    GROUP BY d_year, s_state, i_brand, cs_sold_date_sk
)
SELECT
    u.d_year,
    u.s_state,
    u.i_brand,
    u.total_catalog_sales,
    u.total_store_sales,
    u.total_returns,
    u.avg_catalog_profit,
    u.distinct_orders,
    u.total_quantity_on_hand,
    u.profit_category,
    (
        SELECT AVG(cs.cs_ext_sales_price)
        FROM catalog_sales cs
        WHERE cs.cs_sold_date_sk = u.cs_sold_date_sk
    ) AS avg_sales_price_by_date,
    SUM(u.total_catalog_sales) OVER (
        PARTITION BY u.d_year
        ORDER BY u.total_catalog_sales DESC
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_catalog_sales,
    RANK() OVER (
        PARTITION BY u.d_year
        ORDER BY u.total_catalog_sales DESC
    ) AS sales_rank
FROM (
    SELECT 
        d_year,
        s_state,
        i_brand,
        total_catalog_sales,
        total_store_sales,
        total_returns,
        avg_catalog_profit,
        distinct_orders,
        total_quantity_on_hand,
        profit_category,
        cs_sold_date_sk
    FROM agg
    WHERE total_catalog_sales > 10000
    UNION ALL
    SELECT 
        d_year,
        s_state,
        i_brand,
        total_catalog_sales,
        total_store_sales,
        total_returns,
        avg_catalog_profit,
        distinct_orders,
        total_quantity_on_hand,
        profit_category,
        cs_sold_date_sk
    FROM agg
    WHERE avg_catalog_profit > 0
) u
WHERE u.total_quantity_on_hand > 0
  AND u.profit_category <> 'Negative'
LIMIT 100
