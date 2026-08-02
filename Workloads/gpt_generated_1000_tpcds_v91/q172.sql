WITH base AS (
    SELECT
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        d_sold.d_date,
        w.w_warehouse_id,
        i.i_category,
        i.i_color,
        cc.cc_name,
        s.s_store_name,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        COALESCE(p.p_promo_id, 'NO_PROMO') AS promo_id,
        COALESCE(wr.wr_return_amt, 0) AS return_amt,
        r.r_reason_desc,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        inv.inv_quantity_on_hand,
        t.t_hour AS sold_hour,
        tr.t_hour AS return_hour
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
       AND inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN time_dim tr
        ON wr.wr_returned_time_sk = tr.t_time_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
        d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        AND i.i_color IN ('royal', 'rosy')
        AND cs.cs_quantity > 5
)
SELECT
    sold_year,
    w_warehouse_id,
    i_category,
    i_color,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    SUM(return_amt) AS total_returns,
    COUNT(*) AS order_cnt,
    SUM(CASE WHEN promo_id <> 'NO_PROMO' THEN 1 ELSE 0 END) AS promo_order_cnt,
    AVG(cs_quantity) AS avg_quantity,
    (SUM(cs_net_profit) / NULLIF(SUM(cs_ext_sales_price), 0)) AS profit_margin
FROM base
WHERE
    w_warehouse_id IS NOT NULL
GROUP BY
    sold_year,
    w_warehouse_id,
    i_category,
    i_color
HAVING
    SUM(cs_ext_sales_price) > (SELECT AVG(cs_ext_sales_price) FROM catalog_sales cs)
ORDER BY total_sales DESC
LIMIT 100
