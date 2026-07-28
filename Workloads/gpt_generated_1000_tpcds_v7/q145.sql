WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_profit,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        t.t_time,
        t.t_am_pm,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        s.s_store_name,
        s.s_state,
        w.w_warehouse_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.web_name,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON ss.ss_item_sk = cr.cr_item_sk
        AND d.d_date_sk = cr.cr_returned_date_sk
        AND t.t_time_sk = cr.cr_returned_time_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND d.d_date_sk = sr.sr_returned_date_sk
        AND t.t_time_sk = sr.sr_return_time_sk
    LEFT JOIN web_returns wr
        ON ss.ss_item_sk = wr.wr_item_sk
        AND d.d_date_sk = wr.wr_returned_date_sk
        AND t.t_time_sk = wr.wr_returned_time_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
      AND t.t_am_pm = 'PM'
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
)
SELECT
    base.d_year,
    base.i_category,
    base.s_store_name,
    COUNT(DISTINCT base.ss_ticket_number) AS orders,
    SUM(base.ss_quantity) AS total_quantity_sold,
    SUM(base.ss_sales_price * base.ss_quantity) AS total_sales_amount,
    SUM(COALESCE(base.cr_return_amount, 0)) AS total_catalog_return_amount,
    SUM(COALESCE(base.sr_return_amt, 0)) AS total_store_return_amount,
    SUM(COALESCE(base.wr_return_amt, 0)) AS total_web_return_amount,
    AVG(base.ss_net_profit) AS avg_net_profit_per_order
FROM base
GROUP BY base.d_year, base.i_category, base.s_store_name
HAVING SUM(base.ss_sales_price * base.ss_quantity) > 10000
ORDER BY total_sales_amount DESC
LIMIT 100
