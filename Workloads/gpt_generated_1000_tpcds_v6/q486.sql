WITH
    ws_agg AS (
        SELECT
            ws_order_number,
            ws_sold_date_sk,
            ws_sold_time_sk,
            ws_bill_cdemo_sk,
            ws_bill_hdemo_sk,
            ws_ship_mode_sk,
            ws_warehouse_sk,
            ws_promo_sk,
            SUM(ws_ext_sales_price)   AS total_sales,
            SUM(ws_net_profit)        AS total_profit,
            COUNT(*)                  AS line_cnt
        FROM web_sales
        GROUP BY
            ws_order_number,
            ws_sold_date_sk,
            ws_sold_time_sk,
            ws_bill_cdemo_sk,
            ws_bill_hdemo_sk,
            ws_ship_mode_sk,
            ws_warehouse_sk,
            ws_promo_sk
    ),
    cr_agg AS (
        SELECT
            cr_returned_date_sk,
            COUNT(*)               AS catalog_return_cnt,
            SUM(cr_return_amount)  AS catalog_return_amt
        FROM catalog_returns
        GROUP BY cr_returned_date_sk
    ),
    wr_agg AS (
        SELECT
            wr_order_number,
            COUNT(*)          AS web_return_cnt,
            SUM(wr_return_amt) AS web_return_amt
        FROM web_returns
        GROUP BY wr_order_number
    )
SELECT
    ws_agg.ws_order_number,
    d_sold.d_year,
    d_sold.d_day_name          AS sold_day,
    t_sold.t_hour,
    cd.cd_gender,
    hd.hd_income_band_sk,
    w.w_warehouse_name,
    w.w_state,
    sm.sm_type,
    p.p_promo_name,
    d_promo_start.d_date      AS promo_start_date,
    ws_agg.total_sales,
    ws_agg.total_profit,
    cr_agg.catalog_return_cnt,
    cr_agg.catalog_return_amt,
    wr_agg.web_return_cnt,
    wr_agg.web_return_amt,
    ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY ws_agg.total_profit DESC) AS profit_rank
FROM ws_agg
JOIN date_dim d_sold        ON ws_agg.ws_sold_date_sk   = d_sold.d_date_sk
JOIN time_dim t_sold        ON ws_agg.ws_sold_time_sk   = t_sold.t_time_sk
JOIN ship_mode sm           ON ws_agg.ws_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN warehouse w            ON ws_agg.ws_warehouse_sk   = w.w_warehouse_sk
JOIN promotion p            ON ws_agg.ws_promo_sk       = p.p_promo_sk
JOIN customer_demographics cd ON ws_agg.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws_agg.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN cr_agg            ON cr_agg.cr_returned_date_sk = d_sold.d_date_sk   -- catalog_returns → date_dim rule
LEFT JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk   -- promotion start date rule
LEFT JOIN wr_agg            ON wr_agg.wr_order_number = ws_agg.ws_order_number      -- web_returns → web_sales rule
WHERE
    d_sold.d_year = 2001
    AND t_sold.t_hour BETWEEN 8 AND 12
    AND cd.cd_gender = 'M'
    AND w.w_state = 'CA'
    AND p.p_discount_active = 'Y'
ORDER BY d_sold.d_year, profit_rank
LIMIT 100
