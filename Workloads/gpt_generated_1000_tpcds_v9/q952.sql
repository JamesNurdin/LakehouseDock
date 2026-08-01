WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cc.cc_name,
        cc.cc_state,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        p.p_promo_name,
        p.p_discount_active,
        ibb.ib_lower_bound   AS bill_income_lower,
        ibb.ib_upper_bound   AS bill_income_upper,
        ibs.ib_lower_bound   AS ship_income_lower,
        ibs.ib_upper_bound   AS ship_income_upper,
        d_sold.d_year,
        d_sold.d_month_seq,
        r.r_reason_desc,
        wr.wr_return_amt,
        ws.web_name,
        ws.web_state
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ibb
        ON hd_bill.hd_income_band_sk = ibb.ib_income_band_sk
    JOIN income_band ibs
        ON hd_ship.hd_income_band_sk = ibs.ib_income_band_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_wr
        ON cs.cs_sold_date_sk = d_wr.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d_ws
        ON cs.cs_sold_date_sk = d_ws.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ws.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND cs.cs_quantity > 5
        AND w.w_warehouse_sq_ft > 10000
        AND ibb.ib_lower_bound >= 100000
),
first_agg AS (
    SELECT
        d_year,
        cc_name,
        sm_type,
        SUM(cs_ext_sales_price)      AS total_sales,
        SUM(cs_net_profit)           AS total_profit,
        SUM(wr_return_amt)          AS total_return_amount,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM joined_data
    GROUP BY d_year, cc_name, sm_type
)
SELECT
    d_year,
    cc_name,
    sm_type,
    SUM(total_sales)        AS sum_total_sales,
    SUM(total_profit)       AS sum_total_profit,
    SUM(total_return_amount) AS sum_total_return_amount,
    SUM(order_cnt)          AS sum_order_cnt
FROM first_agg
GROUP BY ROLLUP (d_year, cc_name, sm_type)
HAVING
    SUM(total_sales) > 10000
    AND SUM(total_profit) > 500
    AND SUM(order_cnt) >= 10
ORDER BY sum_total_sales DESC
LIMIT 100
