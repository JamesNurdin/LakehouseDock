WITH ranked_sales AS (
    SELECT
        ca.ca_city,
        i.i_category,
        t.t_shift,
        i.i_item_id,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city, i.i_category ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_city IN ('Fairview', 'Oak Ridge', 'Glendale')
      AND t.t_shift = 'Afternoon'
      AND hd.hd_income_band_sk >= 5
    GROUP BY ca.ca_city, i.i_category, t.t_shift, i.i_item_id
    HAVING SUM(ss.ss_ext_sales_price) > 5000
)
SELECT
    ca_city,
    i_category,
    t_shift,
    i_item_id,
    sales_amount,
    profit_amount,
    sales_rank
FROM ranked_sales
WHERE sales_rank <= 5
ORDER BY ca_city, i_category, sales_rank
