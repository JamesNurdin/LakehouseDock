WITH sales_and_returns AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_wholesale_cost,
        ss.ss_list_price,
        ss.ss_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_ext_wholesale_cost,
        ss.ss_ext_list_price,
        ss.ss_ext_tax,
        ss.ss_coupon_amt,
        ss.ss_net_paid,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_refunded_cash,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        sr.sr_net_loss,
        s.s_store_id,
        s.s_state,
        s.s_gmt_offset,
        s.s_company_id,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_returned_date_sk,
        wr.wr_web_page_sk
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_store_sk = s.s_store_sk
    JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE 
        s.s_gmt_offset = -5.00
        AND s.s_state = 'CA'
        AND s.s_company_id = 1
        AND ss.ss_ext_list_price > 2000.00
        AND ss.ss_quantity >= 2
        AND sr.sr_reason_sk IN (9, 10, 51)
        AND sr.sr_fee > 30.00
        AND ib.ib_lower_bound >= 50000
        AND ib.ib_upper_bound <= 100000
        AND wr.wr_return_quantity > 0
        AND wr.wr_returned_date_sk = 2451234
        AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_web_page_sk = wr.wr_web_page_sk
                AND wp.wp_type = 'product'
                AND wp.wp_char_count > 5000
        )
)
SELECT
    s_store_id,
    s_state,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    hd_vehicle_count,
    COUNT(DISTINCT ss_ticket_number) AS total_sales_transactions,
    SUM(ss_ext_sales_price) AS total_sales_amount,
    SUM(ss_ext_discount_amt) AS total_discount_amount,
    AVG(ss_ext_discount_amt) AS avg_discount_amount,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(sr_net_loss) AS total_return_net_loss,
    SUM(wr_return_amt) AS total_web_return_amount,
    SUM(wr_net_loss) AS total_web_return_net_loss,
    SUM(ss_net_profit) - SUM(COALESCE(sr_net_loss, 0)) - SUM(COALESCE(wr_net_loss, 0)) AS net_profit_adjusted
FROM sales_and_returns
GROUP BY
    s_store_id,
    s_state,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    hd_vehicle_count
ORDER BY net_profit_adjusted DESC
LIMIT 100
