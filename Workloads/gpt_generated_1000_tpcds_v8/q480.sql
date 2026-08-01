WITH distinct_customers AS (
    SELECT DISTINCT c.c_customer_sk, c.c_customer_id
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
),
orders_nr AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
)
SELECT
    cs.cs_order_number,
    d.d_year,
    c.c_customer_id,
    cp.cp_catalog_page_id,
    wp.wp_url,
    hd.hd_income_band_sk,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cs.cs_net_profit DESC) AS rn_year_profit,
    RANK() OVER (ORDER BY cs.cs_net_profit DESC) AS global_profit_rank,
    EXISTS (SELECT 1 FROM web_returns wr WHERE wr.wr_order_number = cs.cs_order_number) AS was_returned,
    u.val AS metric_val,
    s.s_market_manager
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
FULL OUTER JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN distinct_customers c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
CROSS JOIN LATERAL (SELECT ARRAY[cs.cs_quantity, cs.cs_sales_price] AS arr) t
CROSS JOIN UNNEST(t.arr) AS u(val)
WHERE cs.cs_quantity > 5
  AND cs.cs_sales_price > 100
  AND d.d_year BETWEEN 2001 AND 2002
  AND hd.hd_income_band_sk IN (1, 3, 8)
  AND (s.s_market_manager = 'David Smith' OR s.s_market_manager IS NULL)
  AND wp.wp_max_ad_count >= 2
  AND cs.cs_order_number IN (SELECT cs_order_number FROM orders_nr)
ORDER BY global_profit_rank
LIMIT 100
