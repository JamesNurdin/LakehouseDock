WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d_sold.d_year,
        cust_bill.c_customer_sk,
        cust_bill.c_customer_id,
        i.i_item_id,
        i.i_category,
        cc.cc_name,
        sm.sm_type,
        w.w_warehouse_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd_bill.hd_buy_potential,
        CASE WHEN cs.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY cust_bill.c_customer_sk ORDER BY cs.cs_net_paid DESC) AS sales_rank
    FROM catalog_sales cs
    INNER JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    INNER JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    INNER JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    INNER JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d_sold.d_year = 2001
)
,
total_returns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    INNER JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
    GROUP BY wr.wr_item_sk
)
SELECT
    sb.cs_order_number,
    sb.c_customer_id,
    sb.i_item_id,
    sb.i_category,
    sb.cc_name,
    sb.sm_type,
    sb.w_warehouse_name,
    sb.profit_flag,
    sb.sales_rank,
    COALESCE(tr.total_return_amt, 0) AS total_return_amount,
    wp.wp_url,
    CASE 
        WHEN sb.profit_flag = 'PROFIT' AND tr.total_return_amt IS NULL THEN 'HIGH'
        ELSE 'MEDIUM'
    END AS customer_value_segment,
    (SELECT AVG(cs_net_paid) FROM catalog_sales) AS avg_net_paid_overall
FROM sales_base sb
LEFT JOIN total_returns tr
    ON sb.cs_item_sk = tr.wr_item_sk
INNER JOIN web_page wp
    ON wp.wp_customer_sk = sb.c_customer_sk
-- join store through a separate date_dim alias to demonstrate an outer join
LEFT JOIN date_dim d_store
    ON 1 = 1 -- dummy join to make the alias available
INNER JOIN store s
    ON s.s_closed_date_sk = d_store.d_date_sk
    AND d_store.d_year = 2001
WHERE s.s_state = 'CA'
LIMIT 100
