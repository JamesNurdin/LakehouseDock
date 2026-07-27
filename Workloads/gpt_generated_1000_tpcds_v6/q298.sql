WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        c.c_customer_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS line_item_cnt,
        AVG(ws.ws_quantity) AS avg_qty,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        c.c_preferred_cust_flag = 'Y'
        AND hd.hd_dep_count >= 4
        AND ib.ib_lower_bound >= 20000
        AND wp.wp_autogen_flag = 'N'
    GROUP BY
        ws.ws_order_number,
        c.c_customer_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
final_agg AS (
    SELECT
        c_customer_id,
        SUM(total_sales) AS cust_total_sales,
        SUM(total_profit) AS cust_total_profit,
        COUNT(*) AS orders_cnt,
        MAX(sales_rank) AS max_sales_rank
    FROM sales_agg
    WHERE total_sales > 1000
      AND total_profit > 0
    GROUP BY c_customer_id
    HAVING SUM(total_sales) > 5000
)
SELECT
    fa.c_customer_id,
    fa.cust_total_sales,
    fa.cust_total_profit,
    fa.orders_cnt,
    RANK() OVER (ORDER BY fa.cust_total_profit DESC) AS profit_rank,
    EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN customer c2 ON wr.wr_refunded_customer_sk = c2.c_customer_sk
        WHERE c2.c_customer_id = fa.c_customer_id
          AND wr.wr_return_amt > 0
    ) AS any_return_flag
FROM final_agg fa
ORDER BY profit_rank
LIMIT 100
