WITH aggregated AS (
    SELECT
        d_sales.d_month_seq AS month_seq,
        i.i_brand AS brand,
        w.w_warehouse_name AS warehouse_name,
        cc.cc_name AS call_center_name,
        hd.hd_buy_potential AS buy_potential,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
        MIN(i.i_current_price) AS min_price,
        MAX(i.i_current_price) AS max_price
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_returns ON sr.sr_returned_date_sk = d_returns.d_date_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2001
      AND i.i_brand_id = 15
      AND hd.hd_vehicle_count >= 2
      AND cc.cc_employees > 1000000
      AND w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
    GROUP BY
        d_sales.d_month_seq,
        i.i_brand,
        w.w_warehouse_name,
        cc.cc_name,
        hd.hd_buy_potential
)
SELECT
    month_seq,
    brand,
    warehouse_name,
    call_center_name,
    buy_potential,
    total_sales,
    avg_discount,
    order_cnt,
    min_price,
    max_price,
    SUM(total_sales) OVER (PARTITION BY brand ORDER BY month_seq ROWS UNBOUNDED PRECEDING) AS running_brand_sales
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
