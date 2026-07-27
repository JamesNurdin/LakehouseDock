WITH sales_agg AS (
    SELECT
        c.c_customer_id          AS customer_id,
        i.i_category             AS category,
        SUM(sr.sr_return_amt)    AS total_return_amt,
        SUM(cs.cs_sales_price * cs.cs_quantity) AS total_sales,
        AVG(cs.cs_net_profit)    AS avg_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE ca.ca_state = 'CA'
      AND ib.ib_upper_bound >= 80000
      AND sm.sm_type = 'EXPRESS'
    GROUP BY c.c_customer_id, i.i_category
)
SELECT
    customer_id,
    category,
    total_return_amt,
    total_sales,
    avg_net_profit,
    order_count
FROM sales_agg
WHERE total_return_amt > 1000
ORDER BY total_return_amt DESC
LIMIT 100
