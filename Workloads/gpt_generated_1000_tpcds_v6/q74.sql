WITH
sales_agg AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    WHERE d_sales.d_fy_year = 1916
      AND cs.cs_quantity > 5
      AND cs.cs_ext_discount_amt < 1000
      AND t_sales.t_meal_time = 'LUNCH'
      AND ca_bill.ca_state = 'GA'
    GROUP BY cs.cs_ship_mode_sk, cs.cs_warehouse_sk
),
store_ret_agg AS (
    SELECT
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    JOIN customer c_ret ON sr.sr_customer_sk = c_ret.c_customer_sk
    JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
    WHERE d_ret.d_fy_year = 1916
      AND sr.sr_return_quantity > 1
      AND t_ret.t_meal_time = 'AFTERNOON'
      AND ca_ret.ca_state = 'LA'
    GROUP BY sr.sr_store_sk
),
web_ret_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(wr.wr_net_loss) AS total_web_net_loss
    FROM web_returns wr
    JOIN date_dim d_web ON wr.wr_returned_date_sk = d_web.d_date_sk
    JOIN time_dim t_web ON wr.wr_returned_time_sk = t_web.t_time_sk
    JOIN customer c_web ON wr.wr_refunded_customer_sk = c_web.c_customer_sk
    JOIN customer_address ca_web ON wr.wr_refunded_addr_sk = ca_web.ca_address_sk
    WHERE d_web.d_fy_year = 1916
      AND wr.wr_return_quantity > 1
      AND t_web.t_meal_time = 'EVENING'
      AND ca_web.ca_state = 'NY'
    GROUP BY wr.wr_returned_date_sk
)
SELECT *
FROM (
    SELECT
        'Sales' AS source_type,
        sm.sm_ship_mode_id AS category,
        w.w_warehouse_id AS sub_category,
        sa.total_net_paid AS metric,
        ROW_NUMBER() OVER (PARTITION BY 'Sales' ORDER BY sa.total_net_paid DESC) AS rn
    FROM sales_agg sa
    JOIN ship_mode sm ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
    WHERE sm.sm_carrier = 'DHL'

    UNION ALL

    SELECT
        'StoreReturns' AS source_type,
        s.s_store_name AS category,
        NULL AS sub_category,
        sr.total_return_amt AS metric,
        ROW_NUMBER() OVER (PARTITION BY 'StoreReturns' ORDER BY sr.total_return_amt DESC) AS rn
    FROM store_ret_agg sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'LA'

    UNION ALL

    SELECT
        'WebReturns' AS source_type,
        ws.web_name AS category,
        NULL AS sub_category,
        wr.total_web_return_amt AS metric,
        ROW_NUMBER() OVER (PARTITION BY 'WebReturns' ORDER BY wr.total_web_return_amt DESC) AS rn
    FROM web_ret_agg wr
    JOIN web_site ws ON ws.web_open_date_sk = (
        SELECT d_date_sk FROM date_dim WHERE d_fy_year = 1916 LIMIT 1
    )
    WHERE ws.web_state = 'GA'
) combined
WHERE rn <= 10
ORDER BY source_type, rn
LIMIT 100
